"""Mesure un modèle sur `evaluation/data/receipts.json` : libellés de tickets réels.

**Un article se classe seul.** Le scan ne passe plus par l'enseigne, donc la
mesure non plus : ce qui est noté ici est ce que le modèle rend d'un libellé
de caisse, sans rien savoir du ticket où il a été lu. La cascade qui déduisait
la classe d'un article de celle de son enseigne portait un chiffre flatteur —
88,8 % — que le corpus expliquait à lui seul : 63 % des tickets FindIt sont
alimentaires, et l'enseigne suffisait à les trancher.

Deux lectures par variante d'entrée :
- stricte : le slug exact ;
- famille : supermarché/épicerie/marché confondus, restaurant/fast-food/café/bar
  confondus — ces frontières sont des conventions d'enseigne, pas des faits.

Le score qui compte est celui de T1-test : T1-train sert d'entraînement à
tout ce qui apprend des libellés de tickets. `--stores` mesure à part la
lecture des en-têtes d'enseigne : elle ne décide plus d'aucune catégorie, elle
reste ce que le scan affiche.
"""

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

import torch
from transformers import AutoTokenizer

from corpus.receipts.labels import STORE_LABELS
from paths import MODEL_DIR, RECEIPTS_CORPUS
from serving.normalize import normalize_receipt_line
from taxonomy import LABELS
from training.train import BudgetClassifier

CORPUS_PATH = RECEIPTS_CORPUS
DEFAULT_MODEL = MODEL_DIR
BATCH_SIZE = 64
MAX_LENGTH = 64
CONFIDENT = 0.9

FAMILIES = {
    "alimentation.courses": "alimentation",
    "restauration.restaurant": "restauration",
    "restauration.fast_food": "restauration",
    "restauration.cafe": "restauration",
    "restauration.bar": "restauration",
}

# `normalized` est ce que l'app envoie au modèle ; les deux autres disent ce
# que la normalisation rapporte, et ne décrivent aucun chemin de production.
VARIANTS = {
    "raw": lambda row: row["name"],
    "lower": lambda row: row["name"].lower(),
    "normalized": lambda row: normalize_receipt_line(row["name"]),
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


def store_scores(model, tokenizer) -> None:
    """Les en-têtes d'enseigne seuls, contre l'étiquette manuelle.

    Diagnostic, pas décision : depuis que chaque article se classe seul, aucune
    catégorie d'article ne dépend plus de ce chiffre."""
    stores = sorted(STORE_LABELS)
    predictions = predict(model, tokenizer, [normalize_receipt_line(s) for s in stores])
    strict = sum(slug == STORE_LABELS[s] for s, (slug, _c) in zip(stores, predictions))
    loose = sum(family(slug) == family(STORE_LABELS[s]) for s, (slug, _c) in zip(stores, predictions))
    confident = [(s, slug) for s, (slug, c) in zip(stores, predictions) if c >= CONFIDENT]
    confident_ok = sum(family(slug) == family(STORE_LABELS[s]) for s, slug in confident)
    print(f"\n== enseignes ({len(stores)}) ==")
    print(f"  strict {strict / len(stores):.1%}  famille {loose / len(stores):.1%}  "
          f"famille à P≥{CONFIDENT} : {confident_ok}/{len(confident)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--variants", nargs="*", default=list(VARIANTS))
    parser.add_argument("--errors", type=int, default=0, help="exemples d'erreurs T1-test à afficher")
    parser.add_argument("--stores", action="store_true", help="lecture des en-têtes d'enseigne")
    args = parser.parse_args()

    rows = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    model, tokenizer = load_model(args.model)
    if args.stores:
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
