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
from transformers.utils import ModelOutput

from generate_dataset import LABELS

MODEL_NAME = "jhu-clsp/mmBERT-small"
OUTPUT_DIR = Path(__file__).parent / "output"
DATASET_DIR = Path(__file__).parent / "dataset"

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


def load_dataset_from_jsonl(path: Path) -> Dataset:
    rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    return Dataset.from_list(rows)


def tokenize(examples: dict, tokenizer: AutoTokenizer) -> dict:
    out = tokenizer(examples["text"], truncation=True, padding="max_length", max_length=64)
    out["type_labels"] = examples["type_label"]
    out["category_labels"] = examples["category_label"]
    out["recurrence_labels"] = examples["recurrence_label"]
    return out


class MultiLabelDataCollator:
    """Collates batches with multiple label columns."""

    def __call__(self, features: list[dict]) -> dict:
        batch: dict = {}
        for key in ("input_ids", "attention_mask", "type_labels", "category_labels", "recurrence_labels"):
            vals = [f[key] for f in features]
            if isinstance(vals[0], torch.Tensor):
                batch[key] = torch.stack(vals)
            else:
                batch[key] = torch.tensor(vals, dtype=torch.long)
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

    train_dataset = load_dataset_from_jsonl(DATASET_DIR / "train.jsonl")
    eval_dataset = load_dataset_from_jsonl(DATASET_DIR / "eval.jsonl")

    train_dataset = train_dataset.map(lambda ex: tokenize(ex, tokenizer), batched=True)
    eval_dataset = eval_dataset.map(lambda ex: tokenize(ex, tokenizer), batched=True)

    train_dataset.set_format("torch", columns=["input_ids", "attention_mask", "type_labels", "category_labels", "recurrence_labels"])
    eval_dataset.set_format("torch", columns=["input_ids", "attention_mask", "type_labels", "category_labels", "recurrence_labels"])

    training_args = TrainingArguments(
        output_dir=str(OUTPUT_DIR),
        num_train_epochs=5,
        per_device_train_batch_size=16,
        per_device_eval_batch_size=16,
        eval_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="category_f1",
        logging_steps=10,
        seed=42,
        report_to="none",
        warmup_ratio=0.1,
        learning_rate=3e-5,
    )

    trainer = MultiHeadTrainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        compute_metrics=compute_metrics,
        data_collator=MultiLabelDataCollator(),
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
