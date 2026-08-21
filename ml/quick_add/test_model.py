import json
from collections import defaultdict
from pathlib import Path

import torch
from transformers import AutoTokenizer

from generate_dataset import LABELS
from train import BudgetClassifier, BudgetClassifierConfig

MODEL_PATH = Path(__file__).parent / "output" / "best"
CORPUS_PATH = Path(__file__).parent / "eval_corpus.json"

TYPE_LABELS = ["expense", "income"]
REC_LABELS = ["ponctuel", "fixe"]
LEVEL_ORDER = ["easy", "medium", "hard", "app"]


def load_corpus() -> dict[str, list[dict]]:
    """Group the evaluation corpus by level, with labels resolved to indices."""
    raw = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    by_level: dict[str, list[dict]] = defaultdict(list)
    for case in raw["cases"]:
        by_level[case["level"]].append(
            {
                "text": case["input"],
                "type": TYPE_LABELS.index(case["type"]),
                "category": LABELS.index(case["category"]),
                "recurrence": REC_LABELS.index(case["recurrence"]),
            }
        )
    return by_level


def predict(model: BudgetClassifier, tokenizer, text: str) -> dict:
    tokens = tokenizer(text, return_tensors="pt", truncation=True, padding="max_length", max_length=64)
    with torch.no_grad():
        outputs = model(input_ids=tokens["input_ids"], attention_mask=tokens["attention_mask"])

    type_pred = outputs.type_logits.argmax(dim=-1).item()
    cat_pred = outputs.category_logits.argmax(dim=-1).item()
    rec_pred = outputs.recurrence_logits.argmax(dim=-1).item()

    type_conf = torch.softmax(outputs.type_logits, dim=-1).max().item()
    cat_conf = torch.softmax(outputs.category_logits, dim=-1).max().item()
    rec_conf = torch.softmax(outputs.recurrence_logits, dim=-1).max().item()

    return {
        "type": type_pred,
        "category": cat_pred,
        "recurrence": rec_pred,
        "type_conf": type_conf,
        "cat_conf": cat_conf,
        "rec_conf": rec_conf,
    }


def run_test_suite(model: BudgetClassifier, tokenizer, cases: list[dict], level: str) -> dict:
    type_correct = 0
    cat_correct = 0
    rec_correct = 0
    all_correct = 0
    total = len(cases)
    failures: list[str] = []

    for case in cases:
        result = predict(model, tokenizer, case["text"])

        type_ok = result["type"] == case["type"]
        cat_ok = result["category"] == case["category"]
        rec_ok = result["recurrence"] == case["recurrence"]

        if type_ok:
            type_correct += 1
        if cat_ok:
            cat_correct += 1
        if rec_ok:
            rec_correct += 1
        if type_ok and cat_ok and rec_ok:
            all_correct += 1

        if not (type_ok and cat_ok and rec_ok):
            parts: list[str] = []
            if not type_ok:
                parts.append(f"type: {TYPE_LABELS[result['type']]}({result['type_conf']:.0%}) != {TYPE_LABELS[case['type']]}")
            if not cat_ok:
                parts.append(f"cat: {LABELS[result['category']]}({result['cat_conf']:.0%}) != {LABELS[case['category']]}")
            if not rec_ok:
                parts.append(f"rec: {REC_LABELS[result['recurrence']]}({result['rec_conf']:.0%}) != {REC_LABELS[case['recurrence']]}")
            failures.append(f"  '{case['text']}' → {', '.join(parts)}")

    print(f"\n{'='*60}")
    print(f"  [{level.upper()}] {total} tests")
    print(f"  Type:       {type_correct}/{total} ({type_correct/total:.0%})")
    print(f"  Category:   {cat_correct}/{total} ({cat_correct/total:.0%})")
    print(f"  Recurrence: {rec_correct}/{total} ({rec_correct/total:.0%})")
    print(f"  All 3 OK:   {all_correct}/{total} ({all_correct/total:.0%})")

    if failures:
        print(f"\n  Failures:")
        for f in failures:
            print(f)

    return {
        "type_acc": type_correct / total,
        "cat_acc": cat_correct / total,
        "rec_acc": rec_correct / total,
    }


def main() -> None:
    config = BudgetClassifierConfig.from_pretrained(str(MODEL_PATH))
    model = BudgetClassifier.from_pretrained(str(MODEL_PATH), config=config)
    model.eval()

    tokenizer = AutoTokenizer.from_pretrained(str(MODEL_PATH))

    corpus = load_corpus()
    results = {
        level: run_test_suite(model, tokenizer, corpus[level], level)
        for level in LEVEL_ORDER
        if corpus.get(level)
    }

    print(f"\n{'='*60}")
    print("  SUMMARY")
    for level, scores in results.items():
        print(
            f"  {level:8s} — type:{scores['type_acc']:.0%}  "
            f"cat:{scores['cat_acc']:.0%}  rec:{scores['rec_acc']:.0%}"
        )


if __name__ == "__main__":
    main()
