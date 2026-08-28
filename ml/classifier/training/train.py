import json
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
from transformers.trainer_pt_utils import LengthGroupedSampler
from transformers.utils import ModelOutput

from paths import DATASET_DIR, OUTPUT_DIR
from taxonomy import LABELS

MODEL_NAME = "jhu-clsp/mmBERT-small"


MAX_LENGTH = 64
BATCH_SIZE = 32
NUM_EPOCHS = 5
LEARNING_RATE = 5e-5

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


def tokenize(examples: dict, tokenizer: AutoTokenizer) -> dict:
    out = tokenizer(examples["text"], truncation=True, max_length=MAX_LENGTH)
    out["type_labels"] = examples["type_label"]
    out["category_labels"] = examples["category_label"]
    out["recurrence_labels"] = examples["recurrence_label"]
    out["length"] = [len(ids) for ids in out["input_ids"]]
    return out


class MultiLabelDataCollator:
    """Pad au plus long du lot, pas à 64.

    La saisie médiane fait quelques tokens : bourrer jusqu'à 64 multipliait le
    calcul par dix pour un résultat identique, les positions de bourrage étant
    masquées dans l'attention comme dans le mean pooling.
    """

    def __init__(self, pad_token_id: int):
        self.pad_token_id = pad_token_id

    def __call__(self, features: list[dict]) -> dict:
        lengths = [len(feature["input_ids"]) for feature in features]
        width = max(lengths)
        input_ids = torch.full((len(features), width), self.pad_token_id, dtype=torch.long)
        attention_mask = torch.zeros((len(features), width), dtype=torch.long)
        for row, feature in enumerate(features):
            length = lengths[row]
            input_ids[row, :length] = torch.as_tensor(feature["input_ids"], dtype=torch.long)
            attention_mask[row, :length] = torch.as_tensor(
                feature["attention_mask"], dtype=torch.long
            )

        batch: dict = {"input_ids": input_ids, "attention_mask": attention_mask}
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

    train_dataset = train_dataset.map(lambda ex: tokenize(ex, tokenizer), batched=True)
    eval_dataset = eval_dataset.map(lambda ex: tokenize(ex, tokenizer), batched=True)

    columns = [
        "input_ids", "attention_mask", "length",
        "type_labels", "category_labels", "recurrence_labels",
    ]
    train_dataset = train_dataset.select_columns(columns)
    eval_dataset = eval_dataset.select_columns(columns)

    training_args = TrainingArguments(
        output_dir=str(OUTPUT_DIR),
        num_train_epochs=NUM_EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
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
        data_collator=MultiLabelDataCollator(tokenizer.pad_token_id),
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
