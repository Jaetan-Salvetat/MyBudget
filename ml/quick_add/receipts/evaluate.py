"""Mesure un modèle sur `eval_receipts.json` : libellés de tickets réels.

Deux lectures par variante d'entrée :
- stricte : le slug exact ;
- famille : supermarché/épicerie/marché confondus, restaurant/fast-food/café/bar
  confondus — ces frontières sont des conventions d'enseigne, pas des faits.

Le score qui compte est celui de T1-test : T1-train sert d'entraînement à
tout ce qui apprend des libellés de tickets.
"""

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

import torch
from transformers import AutoTokenizer

from receipts.cascade import STORE_MIN_CONFIDENCE, Prediction, item_category, ticket_category
from receipts.labels import STORE_LABELS
from receipts.normalize import normalize_receipt_line
from taxonomy import LABELS
from train import BudgetClassifier

CORPUS_PATH = Path(__file__).resolve().parents[1] / "eval_receipts.json"
DEFAULT_MODEL = Path(__file__).resolve().parents[1] / "output" / "best"
BATCH_SIZE = 64
MAX_LENGTH = 64

FAMILIES = {
    "alimentation.supermarche": "alimentation",
    "alimentation.epicerie": "alimentation",
    "alimentation.marche": "alimentation",
    "restauration.restaurant": "restauration",
    "restauration.fast_food": "restauration",
    "restauration.cafe": "restauration",
    "restauration.bar": "restauration",
}

VARIANTS = {
    "raw": lambda row: row["name"],
    "lower": lambda row: row["name"].lower(),
    "normalized": lambda row: normalize_receipt_line(row["name"]),
    "store+normalized": lambda row: f"{row['store'].lower()} {normalize_receipt_line(row['name'])}".strip(),
}


def family(slug: str) -> str:
    return FAMILIES.get(slug, slug)


def load_model(path: Path):
    model = BudgetClassifier.from_pretrained(path).eval()
    tokenizer = AutoTokenizer.from_pretrained(path)
    return model, tokenizer


def predict(model, tokenizer, texts: list[str]) -> list[tuple[str, float]]:
    out: list[tuple[str, float]] = []
    for start in range(0, len(texts), BATCH_SIZE):
        batch = texts[start : start + BATCH_SIZE]
        encoded = tokenizer(
            batch, return_tensors="pt", padding=True, truncation=True, max_length=MAX_LENGTH
        )
        with torch.no_grad():
            output = model(
                input_ids=encoded["input_ids"], attention_mask=encoded["attention_mask"]
            )
        probabilities = torch.softmax(output.category_logits, dim=-1)
        confidence, index = probabilities.max(dim=-1)
        out.extend(
            (LABELS[i], c) for i, c in zip(index.tolist(), confidence.tolist())
        )
    return out


def score(rows: list[dict], predictions: list[tuple[str, float]]) -> dict:
    strict = Counter()
    loose = Counter()
    total = Counter()
    confusions: Counter[tuple[str, str]] = Counter()
    for row, (slug, _confidence) in zip(rows, predictions):
        split = row["split"]
        total[split] += 1
        if slug == row["category"]:
            strict[split] += 1
        if family(slug) == family(row["category"]):
            loose[split] += 1
        elif split == "test":
            confusions[(row["category"], slug)] += 1
    return {
        "strict": {s: strict[s] / total[s] for s in total},
        "family": {s: loose[s] / total[s] for s in total},
        "total": dict(total),
        "confusions": confusions,
    }


def cascade_scores(rows: list[dict], model, tokenizer, hide_store: bool) -> dict:
    """Rejoue la décision de l'app ticket par ticket."""
    stores = sorted({row["store"] for row in rows if row["store"]})
    store_predictions = dict(zip(stores, predict(model, tokenizer, [normalize_receipt_line(s) for s in stores])))
    item_predictions = predict(model, tokenizer, [normalize_receipt_line(row["name"]) for row in rows])
    by_ticket: dict[str, list[int]] = defaultdict(list)
    for index, row in enumerate(rows):
        by_ticket[row["ticket"]].append(index)
    strict, loose, total = Counter(), Counter(), Counter()
    confusions: Counter[tuple[str, str]] = Counter()
    ticket_ok, ticket_total = Counter(), Counter()
    wrong_stores: Counter[tuple[str, str, str]] = Counter()
    for ticket, indices in by_ticket.items():
        split = rows[indices[0]]["split"]
        store_name = rows[indices[0]]["store"]
        store = None if hide_store or not store_name else Prediction(*store_predictions[store_name])
        items = [Prediction(*item_predictions[i]) for i in indices]
        decided = ticket_category(store, items)
        expected_ticket = Counter(rows[i]["category"] for i in indices).most_common(1)[0][0]
        ticket_total[split] += 1
        if family(decided.slug) == family(expected_ticket):
            ticket_ok[split] += 1
        elif split == "test":
            wrong_stores[(store_name, expected_ticket, decided.slug)] += 1
        for i, item in zip(indices, items):
            slug = item_category(decided, item)
            total[split] += 1
            strict[split] += slug == rows[i]["category"]
            if family(slug) == family(rows[i]["category"]):
                loose[split] += 1
            elif split == "test":
                confusions[(rows[i]["category"], slug)] += 1
    return {
        "strict": {s: strict[s] / total[s] for s in total},
        "family": {s: loose[s] / total[s] for s in total},
        "ticket": {s: ticket_ok[s] / ticket_total[s] for s in ticket_total},
        "total": dict(total),
        "confusions": confusions,
        "wrong_stores": wrong_stores,
    }


def store_scores(model, tokenizer) -> None:
    """Les en-têtes d'enseigne seuls, contre l'étiquette manuelle."""
    stores = sorted(STORE_LABELS)
    predictions = predict(model, tokenizer, [normalize_receipt_line(s) for s in stores])
    strict = sum(slug == STORE_LABELS[s] for s, (slug, _c) in zip(stores, predictions))
    loose = sum(family(slug) == family(STORE_LABELS[s]) for s, (slug, _c) in zip(stores, predictions))
    confident = [(s, slug) for s, (slug, c) in zip(stores, predictions) if c >= STORE_MIN_CONFIDENCE]
    confident_ok = sum(family(slug) == family(STORE_LABELS[s]) for s, slug in confident)
    print(f"\n== enseignes ({len(stores)}) ==")
    print(f"  strict {strict / len(stores):.1%}  famille {loose / len(stores):.1%}  "
          f"famille à P≥{STORE_MIN_CONFIDENCE} : {confident_ok}/{len(confident)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--variants", nargs="*", default=list(VARIANTS))
    parser.add_argument("--errors", type=int, default=0, help="exemples d'erreurs T1-test à afficher")
    parser.add_argument("--cascade", action="store_true", help="rejouer la décision de l'app")
    args = parser.parse_args()

    rows = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    model, tokenizer = load_model(args.model)
    if args.cascade:
        for hide_store in (False, True):
            result = cascade_scores(rows, model, tokenizer, hide_store)
            print(f"\n== cascade {'(enseigne masquée)' if hide_store else '(enseigne lue)'} ==")
            for split in ("train", "test"):
                print(
                    f"  {split:5} n={result['total'][split]:5}  strict {result['strict'][split]:.1%}  "
                    f"famille {result['family'][split]:.1%}  ticket {result['ticket'][split]:.1%}"
                )
            for (expected, predicted), count in result["confusions"].most_common(6):
                print(f"    {count:4}  {expected} → {predicted}")
            if args.errors:
                for (store, expected, predicted), count in result["wrong_stores"].most_common(args.errors):
                    print(f"    ticket ×{count:<3} {store!r:40} {expected} → {predicted}")
        store_scores(model, tokenizer)
    for variant in args.variants:
        texts = [VARIANTS[variant](row) for row in rows]
        predictions = predict(model, tokenizer, texts)
        result = score(rows, predictions)
        print(f"\n== {variant} ==")
        for split in ("train", "test"):
            print(
                f"  {split:5} n={result['total'][split]:5}  "
                f"strict {result['strict'][split]:.1%}  famille {result['family'][split]:.1%}"
            )
        print("  confusions T1-test (attendu → prédit) :")
        for (expected, predicted), count in result["confusions"].most_common(8):
            print(f"    {count:4}  {expected} → {predicted}")
        if args.errors:
            shown = 0
            for row, text, (slug, confidence) in zip(rows, texts, predictions):
                if row["split"] == "test" and family(slug) != family(row["category"]):
                    print(f"    {text!r:50} {row['category']} → {slug} ({confidence:.2f})")
                    shown += 1
                    if shown >= args.errors:
                        break


if __name__ == "__main__":
    sys.exit(main())
