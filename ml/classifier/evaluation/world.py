"""Évaluation de la connaissance monde.

`evaluation/data/quick_add.json` mesure la distribution d'entraînement ; il ne dit rien de ce
qui arrive en production. Ce script sépare deux questions que la moyenne
confond :

- **mémorisation** — les cas dont l'entité figure dans la base moissonnée. Le
  modèle a vu ce nom : s'il se trompe, l'entraînement ne retient pas ce qu'on
  lui donne ;
- **généralisation** — les cas dont l'entité est absente de la base. Le modèle
  ne peut s'appuyer que sur le contexte et son pré-entraînement.

En production la précision vaut « couverture × mémorisation + (1 − couverture)
× généralisation ». Une moyenne unique masquerait lequel des deux termes coince.
"""

import json
from collections import defaultdict

import torch
from transformers import AutoTokenizer

from knowledge.entities import normalize, read_entities
from paths import ENTITIES_PATH, MODEL_DIR, WORLD_CORPUS
from taxonomy import LABELS, canonical
from training.train import BudgetClassifier

MODEL_PATH = MODEL_DIR
CORPUS_PATH = WORLD_CORPUS
MAX_NGRAM = 4
CONFIDENCE_BINS = 10
COVERAGE_LEVELS = (0.7, 0.8, 0.9)

TYPE_LABELS = ["expense", "income"]
RECURRENCE_LABELS = ["ponctuel", "fixe"]


def known_names() -> set[str]:
    names: set[str] = set()
    if not ENTITIES_PATH.exists():
        return names
    for entity in read_entities(ENTITIES_PATH):
        names.add(entity.key)
        names.update(normalize(alias) for alias in entity.aliases)
    from corpus.quick_add.examples import EXAMPLES

    for rows in EXAMPLES.values():
        names.update(normalize(text) for text, _ in rows)
    return names


def is_known(text: str, names: set[str]) -> bool:
    words = normalize(text).split()
    for size in range(min(MAX_NGRAM, len(words)), 0, -1):
        for start in range(len(words) - size + 1):
            if " ".join(words[start : start + size]) in names:
                return True
    return False


def predict(model: BudgetClassifier, tokenizer, text: str) -> dict:
    tokens = tokenizer(text, return_tensors="pt", truncation=True, max_length=64)
    with torch.no_grad():
        output = model(input_ids=tokens["input_ids"], attention_mask=tokens["attention_mask"])
    probabilities = torch.softmax(output.category_logits, dim=-1)
    confidence, index = probabilities.max(dim=-1)
    return {
        "category": LABELS[index.item()],
        "confidence": confidence.item(),
        "type": output.type_logits.argmax(dim=-1).item(),
        "recurrence": output.recurrence_logits.argmax(dim=-1).item(),
    }


def expected_calibration_error(results: list[dict]) -> float:
    bins: dict[int, list[dict]] = defaultdict(list)
    for result in results:
        index = min(CONFIDENCE_BINS - 1, int(result["confidence"] * CONFIDENCE_BINS))
        bins[index].append(result)

    error = 0.0
    for rows in bins.values():
        accuracy = sum(row["correct"] for row in rows) / len(rows)
        confidence = sum(row["confidence"] for row in rows) / len(rows)
        error += len(rows) / len(results) * abs(accuracy - confidence)
    return error


def _rate(rows: list[dict]) -> str:
    if not rows:
        return "—"
    correct = sum(row["correct"] for row in rows)
    return f"{correct}/{len(rows)} = {correct / len(rows):.0%}"


def main() -> None:
    model = BudgetClassifier.from_pretrained(str(MODEL_PATH))
    model.eval()
    tokenizer = AutoTokenizer.from_pretrained(str(MODEL_PATH))
    names = known_names()

    cases = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))["cases"]
    results: list[dict] = []
    for case in cases:
        prediction = predict(model, tokenizer, case["input"])
        expected = canonical(case["category"])
        results.append(
            {
                "input": case["input"],
                "axis": case["axis"],
                "lang": case["lang"],
                "known": is_known(case["input"], names),
                "expected": expected,
                "predicted": prediction["category"],
                "correct": prediction["category"] == expected,
                "confidence": prediction["confidence"],
                "type_correct": TYPE_LABELS[prediction["type"]] == case["type"],
                "recurrence_correct": RECURRENCE_LABELS[prediction["recurrence"]]
                == case["recurrence"],
            }
        )

    known = [row for row in results if row["known"]]
    unknown = [row for row in results if not row["known"]]

    print(f"Cas : {len(results)}  |  couverture de la base : {len(known) / len(results):.0%}")
    print(f"  Catégorie globale   : {_rate(results)}")
    print(f"  Mémorisation        : {_rate(known)}")
    print(f"  Généralisation      : {_rate(unknown)}")
    print(
        f"  Type                : "
        f"{sum(r['type_correct'] for r in results)}/{len(results)}"
    )
    print(
        f"  Récurrence          : "
        f"{sum(r['recurrence_correct'] for r in results)}/{len(results)}"
    )

    print("\nPar axe")
    by_axis: dict[str, list[dict]] = defaultdict(list)
    for row in results:
        by_axis[row["axis"]].append(row)
    for axis, rows in sorted(by_axis.items()):
        print(f"  {axis:16s} {_rate(rows)}")

    print("\nPar langue")
    by_lang: dict[str, list[dict]] = defaultdict(list)
    for row in results:
        by_lang[row["lang"]].append(row)
    for lang, rows in sorted(by_lang.items()):
        print(f"  {lang:16s} {_rate(rows)}")

    print(f"\nCalibration (ECE) : {expected_calibration_error(results):.1%}")
    ordered = sorted(results, key=lambda row: row["confidence"], reverse=True)
    for level in COVERAGE_LEVELS:
        head = ordered[: int(len(ordered) * level)]
        print(f"  précision sur les {level:.0%} plus confiants : {_rate(head)}")

    failures = [row for row in results if not row["correct"]]
    if failures:
        print(f"\nÉchecs ({len(failures)})")
        for row in sorted(failures, key=lambda r: -r["confidence"]):
            flag = "connu " if row["known"] else "inconnu"
            print(
                f"  [{flag}] {row['input']!r} → {row['predicted']} "
                f"({row['confidence']:.0%}) au lieu de {row['expected']}"
            )


if __name__ == "__main__":
    main()
