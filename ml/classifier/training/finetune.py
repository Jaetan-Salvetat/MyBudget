"""Poursuit l'entraînement du modèle livré sur le corpus « style ticket ».

Boucle rapide pour mesurer ce que les libellés de caisse apportent, sans
attendre les deux heures d'un entraînement complet. Une part du corpus général
est rejouée à chaque epoch pour que le quick-add n'oublie rien ; `test_model.py`
et `eval_world.py` restent la non-régression. Le résultat va dans
`output/receipts`, jamais dans `output/best` (seul exemplaire des poids livrés).
"""

import argparse
import json
import random
import sys
from pathlib import Path

from datasets import Dataset
from transformers import AutoTokenizer, TrainingArguments

from paths import DATASET_DIR, OUTPUT_DIR
from training.train import (
    BudgetClassifier,
    MultiHeadTrainer,
    MultiLabelDataCollator,
    compute_metrics,
    load_dataset_from_jsonl,
    tokenize,
)

SOURCE_MODEL = OUTPUT_DIR / "best"
TARGET_MODEL = OUTPUT_DIR / "receipts"
REPLAY_ROWS = 40_000
EPOCHS = 2
LEARNING_RATE = 3e-5
BATCH_SIZE = 32
SEED = 42
COLUMNS = ["input_ids", "attention_mask", "length", "type_labels", "category_labels", "recurrence_labels"]


def replay_rows(path: Path, count: int, rng: random.Random) -> list[dict]:
    rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    rng.shuffle(rows)
    return rows[:count]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=SOURCE_MODEL)
    parser.add_argument("--target", type=Path, default=TARGET_MODEL)
    parser.add_argument("--epochs", type=float, default=EPOCHS)
    parser.add_argument("--replay", type=int, default=REPLAY_ROWS)
    parser.add_argument("--learning-rate", type=float, default=LEARNING_RATE)
    args = parser.parse_args()

    rng = random.Random(SEED)
    tokenizer = AutoTokenizer.from_pretrained(args.source)
    model = BudgetClassifier.from_pretrained(args.source)

    receipts = [json.loads(line) for line in (DATASET_DIR / "receipts_train.jsonl").read_text().splitlines() if line.strip()]
    replay = replay_rows(DATASET_DIR / "train.jsonl", args.replay, rng)
    train_dataset = Dataset.from_list(receipts + replay)
    eval_dataset = load_dataset_from_jsonl(DATASET_DIR / "receipts_eval.jsonl")
    print(f"tickets {len(receipts)} + rejeu {len(replay)} = {len(train_dataset)} ; eval {len(eval_dataset)}")

    train_dataset = train_dataset.map(lambda ex: tokenize(ex, tokenizer), batched=True).select_columns(COLUMNS)
    eval_dataset = eval_dataset.map(lambda ex: tokenize(ex, tokenizer), batched=True).select_columns(COLUMNS)

    training_args = TrainingArguments(
        output_dir=str(args.target / "checkpoints"),
        num_train_epochs=args.epochs,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE * 2,
        remove_unused_columns=False,
        eval_strategy="epoch",
        save_strategy="no",
        logging_steps=50,
        seed=SEED,
        report_to="none",
        warmup_ratio=0.06,
        learning_rate=args.learning_rate,
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
    trainer.save_model(str(args.target))
    tokenizer.save_pretrained(str(args.target))
    metrics = trainer.evaluate()
    for key, value in metrics.items():
        if isinstance(value, float):
            print(f"  {key}: {value:.4f}")


if __name__ == "__main__":
    sys.exit(main())
