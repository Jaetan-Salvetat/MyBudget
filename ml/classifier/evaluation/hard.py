"""Les cas durs des deux entrées, mesurés par axe de difficulté.

`world.py` et `quick_add.py` affichent 95 à 98 % pendant que `generalization.py`
en rend 75,8 %, et le scan annonce 68 % sur un corpus dont 75 % des articles
sont du supermarché. Les trois chiffres sont justes et aucun ne dit ce que
l'utilisateur voit : les corpus écrits à la main reprennent le vocabulaire du
générateur, et le golden FindIt ne mesure qu'une classe sur quatre-vingts.

Deux corpus répondent à ça, un par consommateur du modèle :

- `data/hard_quick_add.json` — ce qu'un francophone tape vraiment, hors des
  gabarits de `corpus/quick_add/build.py`, avec les 79 classes couvertes et
  aucune au-dessus de 5 % du corpus ;
- `data/hard_receipts.json` — des libellés de caisse dans les classes que le
  golden ne mesure sur aucun article, la restauration en tête.

La moyenne d'un corpus dur ne veut rien dire : c'est la colonne par axe qui
désigne où investir. Un axe qui s'effondre est un trou de connaissance ou une
formulation jamais vue, jamais « le modèle est moins bon ».
"""

import json
import random
from collections import defaultdict

import torch
from transformers import AutoTokenizer

from evaluation.generalization import family
from evaluation.robustness import phonetic_vowels, qwerty_key, triple_letter
from paths import DATASET_DIR, EVAL_DATA_DIR, MODEL_DIR
from serving.normalize import normalize_query, normalize_receipt_line
from taxonomy import LABELS
from training.train import MAX_LENGTH, BudgetClassifier

QUICK_ADD_PATH = EVAL_DATA_DIR / "hard_quick_add.json"
RECEIPTS_PATH = EVAL_DATA_DIR / "hard_receipts.json"
BATCH_SIZE = 64
TYPO_SEED = 11

TYPE_LABELS = ["expense", "income"]
RECURRENCE_LABELS = ["ponctuel", "fixe"]

# Le corpus dur porte des formulations courantes — « taxe foncière », « place
# de cinéma » — dont certaines figurent telles quelles à l'entraînement. Les
# mélanger rendrait une moyenne qui confond ce que le modèle a retenu et ce
# qu'il sait déduire ; le partage se calcule ici, jamais dans le JSON, sinon il
# vieillit au premier corpus reconstruit.
def seen_texts(path) -> set[str]:
    if not path.exists():
        return set()
    return {json.loads(line)["text"] for line in path.read_text(encoding="utf-8").splitlines()}


def load(path) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))["cases"]


def predict(model, tokenizer, texts: list[str]) -> list[dict]:
    results: list[dict] = []
    for start in range(0, len(texts), BATCH_SIZE):
        encoded = tokenizer(
            texts[start : start + BATCH_SIZE],
            return_tensors="pt",
            padding=True,
            truncation=True,
            max_length=MAX_LENGTH,
        )
        with torch.no_grad():
            output = model(
                input_ids=encoded["input_ids"], attention_mask=encoded["attention_mask"]
            )
        categories = output.category_logits.argmax(dim=-1).tolist()
        confidences = torch.softmax(output.category_logits, dim=-1).max(dim=-1).values.tolist()
        types = output.type_logits.argmax(dim=-1).tolist()
        recurrences = output.recurrence_logits.argmax(dim=-1).tolist()
        results += [
            {"category": c, "confidence": p, "type": t, "recurrence": r}
            for c, p, t, r in zip(categories, confidences, types, recurrences)
        ]
    return results


def score(rows: list[tuple[dict, dict]]) -> dict:
    """Un axe : justesse stricte, à la famille près, et sur les trois têtes."""
    strict = sum(LABELS[p["category"]] == c["category"] for c, p in rows)
    loose = sum(family(LABELS[p["category"]]) == family(c["category"]) for c, p in rows)
    return {
        "n": len(rows),
        "strict": strict / len(rows),
        "family": loose / len(rows),
        "confidence": sum(p["confidence"] for _, p in rows) / len(rows),
    }


def report(title: str, scored: dict[str, dict], columns: tuple[str, ...]) -> None:
    print(f"\n{'=' * 74}\n  {title}")
    header = "".join(f"{name:>12}" for name in columns)
    print(f"  {'axe':<20}{'n':>5}{header}")
    for axis, values in scored.items():
        cells = "".join(f"{values[name]:>11.1%}" for name in columns)
        print(f"  {axis:<20}{values['n']:>5}{cells}")


def measure_quick_add(model, tokenizer) -> None:
    cases = load(QUICK_ADD_PATH)
    predictions = predict(model, tokenizer, [normalize_query(c["input"]) for c in cases])

    by_axis: dict[str, list] = defaultdict(list)
    for case, prediction in zip(cases, predictions):
        by_axis[case["axis"]].append((case, prediction))

    scored = {}
    for axis, rows in by_axis.items():
        values = score(rows)
        values["type"] = sum(
            TYPE_LABELS[p["type"]] == c["type"] for c, p in rows
        ) / len(rows)
        values["recurrence"] = sum(
            RECURRENCE_LABELS[p["recurrence"]] == c["recurrence"] for c, p in rows
        ) / len(rows)
        scored[axis] = values
    scored["— ensemble —"] = {
        **score(list(zip(cases, predictions))),
        "type": sum(TYPE_LABELS[p["type"]] == c["type"] for c, p in zip(cases, predictions))
        / len(cases),
        "recurrence": sum(
            RECURRENCE_LABELS[p["recurrence"]] == c["recurrence"]
            for c, p in zip(cases, predictions)
        )
        / len(cases),
    }
    report(
        "QUICK-ADD — ce qu'un utilisateur tape",
        scored,
        ("strict", "family", "type", "recurrence", "confidence"),
    )

    trained = seen_texts(DATASET_DIR / "train.jsonl")
    split: dict[str, list] = defaultdict(list)
    for case, prediction in zip(cases, predictions):
        key = "vu à l'entraînement" if normalize_query(case["input"]) in trained else "jamais vu"
        split[key].append((case, prediction))
    report(
        "QUICK-ADD — mémorisation contre déduction",
        {key: score(rows) for key, rows in split.items()},
        ("strict", "family", "confidence"),
    )

    failures = [
        (c["axis"], c["input"], LABELS[p["category"]], c["category"], p["confidence"])
        for c, p in zip(cases, predictions)
        if LABELS[p["category"]] != c["category"]
    ]
    print(f"\n  {len(failures)} échecs de catégorie :")
    for axis, text, got, expected, confidence in failures:
        print(f"    [{axis}] '{text}' → {got} ({confidence:.0%}) au lieu de {expected}")


def measure_typed_input(model, tokenizer) -> None:
    """Le corpus dur est écrit sans faute ; personne ne tape sans faute.

    Les trois opérateurs sont ceux de `robustness.py`, tenus à l'écart de ceux
    de l'entraînement : mesurer un modèle avec le bruit qu'on lui a servi ne
    mesure que sa mémoire. Un par cas, à tour de rôle, tirage déterministe.
    """
    cases = load(QUICK_ADD_PATH)
    rng = random.Random(TYPO_SEED)
    operators = (triple_letter, phonetic_vowels, qwerty_key)

    clean = predict(model, tokenizer, [normalize_query(c["input"]) for c in cases])
    typed = predict(
        model,
        tokenizer,
        [normalize_query(operators[i % 3](c["input"], rng)) for i, c in enumerate(cases)],
    )

    by_axis: dict[str, list] = defaultdict(list)
    for case, before, after in zip(cases, clean, typed):
        by_axis[case["axis"]].append((case, before, after))

    scored = {}
    for axis, rows in by_axis.items():
        pairs = [(c, b) for c, b, _ in rows]
        typo_pairs = [(c, a) for c, _, a in rows]
        scored[axis] = {
            "n": len(rows),
            "propre": score(pairs)["strict"],
            "une faute": score(typo_pairs)["strict"],
            "chute": score(pairs)["strict"] - score(typo_pairs)["strict"],
        }
    scored["— ensemble —"] = {
        "n": len(cases),
        "propre": score(list(zip(cases, clean)))["strict"],
        "une faute": score(list(zip(cases, typed)))["strict"],
        "chute": score(list(zip(cases, clean)))["strict"]
        - score(list(zip(cases, typed)))["strict"],
    }
    report(
        "QUICK-ADD — ce que coûte une faute de frappe sur les cas durs",
        scored,
        ("propre", "une faute", "chute"),
    )


def measure_receipts(model, tokenizer) -> None:
    cases = load(RECEIPTS_PATH)
    predictions = predict(model, tokenizer, [normalize_receipt_line(c["name"]) for c in cases])

    by_axis: dict[str, list] = defaultdict(list)
    for case, prediction in zip(cases, predictions):
        by_axis[case["axis"]].append((case, prediction))

    scored = {axis: score(rows) for axis, rows in by_axis.items()}
    scored["— ensemble —"] = score(list(zip(cases, predictions)))
    report(
        "SCAN — libellés de caisse, article seul",
        scored,
        ("strict", "family", "confidence"),
    )

    failures = [
        (c["axis"], c["name"], LABELS[p["category"]], c["category"], p["confidence"])
        for c, p in zip(cases, predictions)
        if LABELS[p["category"]] != c["category"]
    ]
    print(f"\n  {len(failures)} échecs de catégorie :")
    for axis, name, got, expected, confidence in failures:
        print(f"    [{axis}] '{name}' → {got} ({confidence:.0%}) au lieu de {expected}")


def main() -> None:
    tokenizer = AutoTokenizer.from_pretrained(str(MODEL_DIR))
    model = BudgetClassifier.from_pretrained(str(MODEL_DIR))
    model.eval()

    measure_quick_add(model, tokenizer)
    measure_typed_input(model, tokenizer)
    measure_receipts(model, tokenizer)


if __name__ == "__main__":
    main()
