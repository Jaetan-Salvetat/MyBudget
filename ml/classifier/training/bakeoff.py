"""Banc d'essai entre backbones, à recette identique.

Le seul chiffre qui départage un backbone pour notre tâche est sa justesse sur
des entités jamais vues — `dataset/eval.jsonl`, dont la coupe est faite par
entité. Une epoch suffit à classer les candidats ; l'entraînement complet ne
sert qu'à celui qu'on garde.

    uv run python -m training.bakeoff jhu-clsp/mmBERT-small EuroBERT/EuroBERT-210m

Rien n'est sauvegardé : ce module mesure, il ne produit pas d'artefact.
"""

import argparse
import json
import random

import torch
import torch.nn as nn
from datasets import Dataset
from transformers import AutoModel, AutoTokenizer, TrainingArguments

from evaluation.generalization import family
from paths import DATASET_DIR, OUTPUT_DIR

RESULTS_PATH = OUTPUT_DIR / "bakeoff" / "results.json"
from taxonomy import LABELS
from training.train import (
    BATCH_SIZE,
    CORRUPTION_SEED,
    LEARNING_RATE,
    NUM_RECURRENCES,
    NUM_TYPES,
    ClassificationHead,
    MultiHeadOutput,
    MultiHeadTrainer,
    MultiLabelDataCollator,
    compute_metrics,
    load_dataset_from_jsonl,
    mean_pool,
    measure,
    read_jsonl,
)

COLUMNS = ["text", "length", "type_labels", "category_labels", "recurrence_labels"]


class BakeoffModel(nn.Module):
    """Le même montage que le modèle livré, sur un backbone quelconque.

    `BudgetClassifier` est soudé à ModernBERT par sa config ; le refactoriser
    pour une mesure exposerait le modèle en production à un format de
    checkpoint incompatible. Ici on remonte les mêmes têtes sur un `AutoModel`,
    et rien de ce qui sert à livrer n'est touché.
    """

    def __init__(self, repo: str):
        super().__init__()
        self.backbone = AutoModel.from_pretrained(repo, dtype=torch.float32)
        hidden = self.backbone.config.hidden_size
        self.type_head = ClassificationHead(hidden, NUM_TYPES)
        self.category_head = ClassificationHead(hidden, len(LABELS))
        self.recurrence_head = ClassificationHead(hidden, NUM_RECURRENCES)

    def forward(self, input_ids=None, attention_mask=None, type_labels=None,
                category_labels=None, recurrence_labels=None) -> MultiHeadOutput:
        hidden = self.backbone(
            input_ids=input_ids, attention_mask=attention_mask
        ).last_hidden_state
        pooled = mean_pool(hidden, attention_mask)
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


def prepare(tokenizer, rows: list[dict] | Dataset) -> Dataset:
    dataset = rows if isinstance(rows, Dataset) else Dataset.from_list(rows)
    dataset = dataset.map(lambda batch: measure(batch, tokenizer), batched=True)
    return dataset.select_columns(COLUMNS)


def family_accuracy(trainer: MultiHeadTrainer, dataset: Dataset) -> float:
    output = trainer.predict(dataset)
    predicted = output.predictions[1].argmax(axis=-1)
    expected = output.label_ids[1]
    return sum(
        family(LABELS[p]) == family(LABELS[e]) for p, e in zip(predicted, expected)
    ) / len(expected)


def run(repo: str, epochs: float, with_receipts: bool) -> dict:
    tokenizer = AutoTokenizer.from_pretrained(repo)
    rows = read_jsonl(DATASET_DIR / "train.jsonl")
    if with_receipts and (DATASET_DIR / "receipts_train.jsonl").exists():
        rows += read_jsonl(DATASET_DIR / "receipts_train.jsonl")

    train_dataset = prepare(tokenizer, rows)
    eval_dataset = prepare(tokenizer, load_dataset_from_jsonl(DATASET_DIR / "eval.jsonl"))

    arguments = TrainingArguments(
        output_dir=str(OUTPUT_DIR / "bakeoff"),
        num_train_epochs=epochs,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE * 2,
        remove_unused_columns=False,
        eval_strategy="no",
        save_strategy="no",
        logging_steps=100,
        seed=42,
        report_to="none",
        warmup_ratio=0.06,
        learning_rate=LEARNING_RATE,
        weight_decay=0.01,
        lr_scheduler_type="cosine",
    )
    trainer = MultiHeadTrainer(
        model=BakeoffModel(repo),
        args=arguments,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        compute_metrics=compute_metrics,
        data_collator=MultiLabelDataCollator(tokenizer, random.Random(CORRUPTION_SEED)),
    )
    trainer.train()
    metrics = trainer.evaluate()
    metrics["eval_category_family"] = family_accuracy(trainer, eval_dataset)
    return metrics


HEADER = f"{'backbone':34s} {'catégorie':>10s} {'famille':>9s} {'type':>7s} {'récurrence':>11s}"


def row(repo: str, metrics: dict) -> str:
    return (
        f"{repo:34s} {metrics['eval_category_accuracy']:9.1%} "
        f"{metrics['eval_category_family']:8.1%} "
        f"{metrics['eval_type_accuracy']:6.1%} {metrics['eval_recurrence_accuracy']:10.1%}"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("backbones", nargs="+")
    parser.add_argument("--epochs", type=float, default=1.0)
    parser.add_argument("--with-receipts", action="store_true")
    options = parser.parse_args()

    # Chaque backbone coute une demi-heure ou plus : son resultat est ecrit des
    # qu'il existe. Attendre la fin de la serie pour tout imprimer perd les
    # premiers si le dernier casse.
    results: dict[str, dict] = {}
    RESULTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    for repo in options.backbones:
        print(f"\n=== {repo} ===", flush=True)
        results[repo] = run(repo, options.epochs, options.with_receipts)
        print(f"\n{HEADER}\n{row(repo, results[repo])}", flush=True)
        RESULTS_PATH.write_text(json.dumps(results, indent=2), encoding="utf-8")

    print(f"\n=== Entités jamais vues, {options.epochs} epoch(s) ===")
    print(HEADER)
    for repo, metrics in results.items():
        print(row(repo, metrics))


if __name__ == "__main__":
    main()
