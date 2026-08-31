import json
import os
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import torch
import torch.nn as nn
from datasets import Dataset
from sklearn.metrics import accuracy_score, f1_score
from transformers import (
    AutoTokenizer,
    ModernBertConfig,
    ModernBertModel,
    PreTrainedModel,
    Trainer,
    TrainingArguments,
)
from transformers import TrainerCallback
from transformers.trainer_pt_utils import LengthGroupedSampler
from transformers.utils import ModelOutput

from paths import DATASET_DIR, OUTPUT_DIR
from taxonomy import LABELS
from training.corruption import corrupt

# Le backbone se surcharge par l'environnement, comme `CLASSIFIER_OUTPUT` : un
# banc entre deux tailles doit se lancer sans toucher au fichier, sinon les deux
# runs ne sortent pas de la même recette. Toute famille ModernBERT convient —
# `BudgetClassifier` monte ses têtes sur `ModernBertModel`.
MODEL_NAME = os.environ.get("CLASSIFIER_BACKBONE", "jhu-clsp/mmBERT-small")


MAX_LENGTH = 64
# Le lot se scinde par l'environnement sans changer la recette : ce qui compte
# pour l'optimiseur est `BATCH_SIZE × ACCUMULATION_STEPS`, et il vaut 32 des
# deux côtés du banc. mmBERT-base à 288 M paramètres s'est fait tuer par le
# système au step 4 550 avec un lot de 32 ; le scinder en deux demi-lots divise
# la mémoire d'activations sans toucher au gradient appliqué.
BATCH_SIZE = int(os.environ.get("CLASSIFIER_BATCH", "32"))
ACCUMULATION_STEPS = int(os.environ.get("CLASSIFIER_ACCUMULATION", "1"))
# Recalculer les activations au lieu de les garder coûte ~30 % de temps et
# rend la mémoire du backbone. Le gradient appliqué est identique — c'est ce
# qui permet de mesurer un backbone plus large sans changer la recette.
GRADIENT_CHECKPOINTING = os.environ.get("CLASSIFIER_CHECKPOINTING") == "1"
MPS_CACHE_EVERY = int(os.environ.get("CLASSIFIER_MPS_CACHE_EVERY", "0"))
NUM_EPOCHS = 5
LEARNING_RATE = 5e-5

CORRUPTION_SEED = 1312

NUM_TYPES = 2
NUM_CATEGORIES = len(LABELS)
NUM_RECURRENCES = 2


@dataclass
class MultiHeadOutput(ModelOutput):
    """Output of the multi-head budget classifier."""

    loss: Optional[torch.FloatTensor] = None
    type_logits: torch.FloatTensor = None
    category_logits: torch.FloatTensor = None
    recurrence_logits: torch.FloatTensor = None


class BudgetClassifierConfig(ModernBertConfig):
    """Configuration extending ModernBertConfig with head dimensions."""

    model_type = "budget_classifier"

    def __init__(
        self,
        num_types: int = NUM_TYPES,
        num_categories: int = NUM_CATEGORIES,
        num_recurrences: int = NUM_RECURRENCES,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.num_types = num_types
        self.num_categories = num_categories
        self.num_recurrences = num_recurrences


class ClassificationHead(nn.Module):
    """Replicates ModernBERT's classifier head: Dense(no bias) → GELU → LayerNorm(no bias) → Dropout → Linear."""

    def __init__(self, hidden_size: int, num_classes: int, dropout: float = 0.1):
        super().__init__()
        self.dense = nn.Linear(hidden_size, hidden_size, bias=False)
        self.act = nn.GELU()
        self.norm = nn.LayerNorm(hidden_size, bias=False)
        self.drop = nn.Dropout(dropout)
        self.classifier = nn.Linear(hidden_size, num_classes)

    def forward(self, pooled: torch.Tensor) -> torch.Tensor:
        x = self.dense(pooled)
        x = self.act(x)
        x = self.norm(x)
        x = self.drop(x)
        return self.classifier(x)


def mean_pool(last_hidden_state: torch.Tensor, attention_mask: torch.Tensor) -> torch.Tensor:
    """Mean pooling over non-padded tokens (ModernBERT's default pooling)."""
    mask = attention_mask.unsqueeze(-1).float()
    return (last_hidden_state * mask).sum(dim=1) / mask.sum(dim=1).clamp(min=1e-9)


class BudgetClassifier(PreTrainedModel):
    """ModernBERT backbone with 3 classification heads: type, category, recurrence."""

    config_class = BudgetClassifierConfig
    # Le backbone sait recalculer ses activations ; sans cette déclaration sur
    # l'enveloppe, `gradient_checkpointing_enable` refuse et rien ne propage.
    supports_gradient_checkpointing = True

    def __init__(self, config: BudgetClassifierConfig):
        super().__init__(config)
        self.backbone = ModernBertModel(config)
        h = config.hidden_size
        self.type_head = ClassificationHead(h, config.num_types)
        self.category_head = ClassificationHead(h, config.num_categories)
        self.recurrence_head = ClassificationHead(h, config.num_recurrences)
        self.post_init()

    def forward(
        self,
        input_ids: Optional[torch.LongTensor] = None,
        attention_mask: Optional[torch.FloatTensor] = None,
        type_labels: Optional[torch.LongTensor] = None,
        category_labels: Optional[torch.LongTensor] = None,
        recurrence_labels: Optional[torch.LongTensor] = None,
    ) -> MultiHeadOutput:
        outputs = self.backbone(input_ids=input_ids, attention_mask=attention_mask)
        pooled = mean_pool(outputs.last_hidden_state, attention_mask)

        type_logits = self.type_head(pooled)
        category_logits = self.category_head(pooled)
        recurrence_logits = self.recurrence_head(pooled)

        loss = None
        if type_labels is not None:
            ce = nn.CrossEntropyLoss()
            loss = (
                ce(type_logits, type_labels)
                + ce(category_logits, category_labels)
                + ce(recurrence_logits, recurrence_labels)
            )

        return MultiHeadOutput(
            loss=loss,
            type_logits=type_logits,
            category_logits=category_logits,
            recurrence_logits=recurrence_logits,
        )


class MpsCacheCleaner(TrainerCallback):
    """Rend au système ce que l'allocateur MPS garde en réserve.

    Le gradient de la matrice d'embedding fait 750 Mio d'un bloc — 256 000 × 768
    × 4 octets — et il est redemandé à chaque rétropropagation. L'allocateur
    garde les blocs libérés, la mémoire unifiée se fragmente, et l'échec arrive
    sur une demande que la machine pourrait pourtant servir. Vider le cache
    régulièrement ne change aucun calcul : c'est de l'hygiène d'allocateur.
    """

    def __init__(self, every: int):
        self.every = every

    def on_step_end(self, args, state, control, **kwargs):
        if self.every and state.global_step % self.every == 0:
            torch.mps.empty_cache()


class MultiHeadTrainer(Trainer):
    """Trainer subclass that routes labels to the multi-head model."""

    def _get_train_sampler(self, train_dataset=None) -> torch.utils.data.Sampler:
        """Regroupe les saisies de longueur voisine dans un même lot.

        Avec un padding dynamique, mélanger une saisie de 4 tokens et une de 60
        ramène tout le lot à 60. Le regroupement rend au padding dynamique le
        gain qu'un mélange uniforme lui reprend.
        """
        dataset = train_dataset if train_dataset is not None else self.train_dataset
        return LengthGroupedSampler(
            batch_size=self.args.train_batch_size,
            dataset=dataset,
            lengths=list(dataset["length"]),
        )

    def get_eval_dataloader(self, eval_dataset=None):
        """L'évaluation lit le texte propre : le bruit est un outil d'entraînement."""
        collator = self.data_collator
        self.data_collator = collator.without_noise()
        try:
            return super().get_eval_dataloader(eval_dataset)
        finally:
            self.data_collator = collator

    def compute_loss(self, model, inputs, return_outputs=False, **kwargs):
        outputs = model(
            input_ids=inputs["input_ids"],
            attention_mask=inputs["attention_mask"],
            type_labels=inputs.get("type_labels"),
            category_labels=inputs.get("category_labels"),
            recurrence_labels=inputs.get("recurrence_labels"),
        )
        return (outputs.loss, outputs) if return_outputs else outputs.loss

    def prediction_step(self, model, inputs, prediction_loss_only, ignore_keys=None):
        inputs = self._prepare_inputs(inputs)
        with torch.no_grad():
            outputs = model(
                input_ids=inputs["input_ids"],
                attention_mask=inputs["attention_mask"],
                type_labels=inputs.get("type_labels"),
                category_labels=inputs.get("category_labels"),
                recurrence_labels=inputs.get("recurrence_labels"),
            )

        loss = outputs.loss
        if prediction_loss_only:
            return (loss, None, None)

        logits = (outputs.type_logits, outputs.category_logits, outputs.recurrence_logits)
        labels = (inputs["type_labels"], inputs["category_labels"], inputs["recurrence_labels"])
        return (loss, logits, labels)


def compute_metrics(eval_pred) -> dict:
    """Per-head accuracy and f1."""
    logits, labels = eval_pred
    type_logits, cat_logits, rec_logits = logits
    type_labels, cat_labels, rec_labels = labels

    type_preds = type_logits.argmax(axis=-1)
    cat_preds = cat_logits.argmax(axis=-1)
    rec_preds = rec_logits.argmax(axis=-1)

    return {
        "type_accuracy": accuracy_score(type_labels, type_preds),
        "type_f1": f1_score(type_labels, type_preds, average="macro"),
        "category_accuracy": accuracy_score(cat_labels, cat_preds),
        "category_f1": f1_score(cat_labels, cat_preds, average="macro", zero_division=0),
        "recurrence_accuracy": accuracy_score(rec_labels, rec_preds),
        "recurrence_f1": f1_score(rec_labels, rec_preds, average="macro"),
    }


def read_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def load_dataset_from_jsonl(path: Path) -> Dataset:
    return Dataset.from_list(read_jsonl(path))


def training_rows(dataset_dir: Path) -> list[dict]:
    """Le corpus quick-add, plus le corpus « style ticket » s'il a été généré.

    Les deux servent le même modèle : le scan lit des libellés de caisse, le
    quick-add des saisies libres, et l'app ne charge qu'un seul ONNX.
    """
    rows = read_jsonl(dataset_dir / "train.jsonl")
    receipts = dataset_dir / "receipts_train.jsonl"
    if receipts.exists():
        rows.extend(read_jsonl(receipts))
    return rows


def measure(examples: dict, tokenizer: AutoTokenizer) -> dict:
    """Longueur et étiquettes ; le texte, lui, n'est tokenisé qu'au dernier moment.

    Tokeniser une fois pour toutes figerait la phrase : la faute de frappe doit
    changer à chaque epoch pour que le modèle n'ait rien à mémoriser d'elle.
    """
    encoded = tokenizer(examples["text"], truncation=True, max_length=MAX_LENGTH)
    return {
        "type_labels": examples["type_label"],
        "category_labels": examples["category_label"],
        "recurrence_labels": examples["recurrence_label"],
        "length": [len(ids) for ids in encoded["input_ids"]],
    }


class MultiLabelDataCollator:
    """Tokenise le lot, le bruite s'il sert à l'entraînement, et pad au plus long.

    La saisie médiane fait quelques tokens : bourrer jusqu'à 64 multipliait le
    calcul par dix pour un résultat identique, les positions de bourrage étant
    masquées dans l'attention comme dans le mean pooling.
    """

    def __init__(self, tokenizer: AutoTokenizer, noise: random.Random | None):
        self.tokenizer = tokenizer
        self.noise = noise

    def without_noise(self) -> "MultiLabelDataCollator":
        return MultiLabelDataCollator(self.tokenizer, None)

    def __call__(self, features: list[dict]) -> dict:
        texts = [feature["text"] for feature in features]
        if self.noise is not None:
            texts = [corrupt(text, self.noise) for text in texts]

        encoded = self.tokenizer(
            texts,
            truncation=True,
            max_length=MAX_LENGTH,
            padding=True,
            return_tensors="pt",
        )
        batch: dict = {
            "input_ids": encoded["input_ids"],
            "attention_mask": encoded["attention_mask"],
        }
        for key in ("type_labels", "category_labels", "recurrence_labels"):
            batch[key] = torch.tensor([feature[key] for feature in features], dtype=torch.long)
        return batch


def main() -> None:
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

    config = BudgetClassifierConfig.from_pretrained(
        MODEL_NAME,
        num_types=NUM_TYPES,
        num_categories=NUM_CATEGORIES,
        num_recurrences=NUM_RECURRENCES,
    )
    model = BudgetClassifier(config)
    model.backbone = ModernBertModel.from_pretrained(MODEL_NAME)

    train_dataset = Dataset.from_list(training_rows(DATASET_DIR))
    eval_dataset = load_dataset_from_jsonl(DATASET_DIR / "eval.jsonl")

    train_dataset = train_dataset.map(lambda ex: measure(ex, tokenizer), batched=True)
    eval_dataset = eval_dataset.map(lambda ex: measure(ex, tokenizer), batched=True)

    columns = [
        "text", "length",
        "type_labels", "category_labels", "recurrence_labels",
    ]
    train_dataset = train_dataset.select_columns(columns)
    eval_dataset = eval_dataset.select_columns(columns)

    training_args = TrainingArguments(
        output_dir=str(OUTPUT_DIR),
        num_train_epochs=NUM_EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=ACCUMULATION_STEPS,
        gradient_checkpointing=GRADIENT_CHECKPOINTING,
        per_device_eval_batch_size=BATCH_SIZE * 2,
        remove_unused_columns=False,
        eval_strategy="epoch",
        save_strategy="epoch",
        # Sans limite, chaque epoch laisse 1.6 Go de reprise sur le disque.
        # Seul le meilleur checkpoint sert, il est copie dans output/best.
        save_total_limit=1,
        load_best_model_at_end=True,
        metric_for_best_model="category_f1",
        logging_steps=10,
        seed=42,
        report_to="none",
        warmup_ratio=0.06,
        learning_rate=LEARNING_RATE,
        weight_decay=0.01,
        lr_scheduler_type="cosine",
    )

    trainer = MultiHeadTrainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        compute_metrics=compute_metrics,
        data_collator=MultiLabelDataCollator(tokenizer, random.Random(CORRUPTION_SEED)),
        callbacks=[MpsCacheCleaner(MPS_CACHE_EVERY)] if MPS_CACHE_EVERY else None,
    )

    trainer.train()
    trainer.save_model(str(OUTPUT_DIR / "best"))
    tokenizer.save_pretrained(str(OUTPUT_DIR / "best"))

    metrics = trainer.evaluate()
    print("\n=== Résultats finaux ===")
    for key, value in metrics.items():
        if isinstance(value, float):
            print(f"  {key}: {value:.4f}")
        else:
            print(f"  {key}: {value}")


if __name__ == "__main__":
    main()
