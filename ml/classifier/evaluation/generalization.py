"""Ce que le modèle sait d'un nom qu'il n'a jamais vu.

`evaluation/world.py` mesure la mémorisation et rien d'autre : 293 de ses 294
cas avaient leur entité dans `entities.jsonl`, la ligne « Généralisation »
portait sur un seul cas. Le chiffre de 96 % qu'il annonçait valait pour les
noms de la base, pas pour ce qu'un utilisateur tape.

`dataset/eval.jsonl` est le seul corpus où la question se pose : la coupe du
corpus se fait par entité, donc aucun de ces noms n'a été vu à l'entraînement.
C'est le chiffre qui doit entrer dans la grille d'acceptation.
"""

import json
from collections import Counter, defaultdict

import torch
from transformers import AutoTokenizer

from paths import DATASET_DIR, MODEL_DIR
from taxonomy import LABELS
from training.train import BudgetClassifier

EVAL_PATH = DATASET_DIR / "eval.jsonl"
BATCH_SIZE = 128
MAX_LENGTH = 64
COVERAGE_LEVELS = (0.5, 0.7, 0.8, 0.9)
MIN_CLASS_SIZE = 30
WEAKEST_CLASSES = 12
TOP_CONFUSIONS = 15

# Supermarché / épicerie / marché et restaurant / fast-food / café / bar sont
# des conventions d'enseigne, pas des faits : les confondre isole ce que des
# données supplémentaires peuvent encore corriger.
FAMILIES = {
    "alimentation.supermarche": "alimentation.courses",
    "alimentation.epicerie": "alimentation.courses",
    "alimentation.marche": "alimentation.courses",
    "restauration.restaurant": "restauration.sortie",
    "restauration.fast_food": "restauration.sortie",
    "restauration.cafe": "restauration.sortie",
    "restauration.bar": "restauration.sortie",
}


def family(slug: str) -> str:
    return FAMILIES.get(slug, slug)


def read_rows() -> list[dict]:
    if not EVAL_PATH.exists():
        raise FileNotFoundError(
            f"{EVAL_PATH} absent : lancer d'abord `python -m corpus.quick_add.build`"
        )
    return [json.loads(line) for line in EVAL_PATH.read_text(encoding="utf-8").splitlines()]


def predict(model, tokenizer, texts: list[str]) -> tuple[list[int], list[float]]:
    indices: list[int] = []
    confidences: list[float] = []
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
        confidence, index = torch.softmax(output.category_logits, dim=-1).max(dim=-1)
        indices += index.tolist()
        confidences += confidence.tolist()
    return indices, confidences


def main() -> None:
    rows = read_rows()
    model = BudgetClassifier.from_pretrained(str(MODEL_DIR)).eval()
    tokenizer = AutoTokenizer.from_pretrained(str(MODEL_DIR))
    predicted, confidences = predict(model, tokenizer, [row["text"] for row in rows])

    expected = [row["category_label"] for row in rows]
    strict = sum(p == e for p, e in zip(predicted, expected))
    same_family = sum(
        family(LABELS[p]) == family(LABELS[e]) for p, e in zip(predicted, expected)
    )

    print(f"Entités jamais vues : {len(rows)}")
    print(f"  Catégorie stricte : {strict}/{len(rows)} = {strict / len(rows):.1%}")
    print(f"  À la famille près : {same_family / len(rows):.1%}")

    order = sorted(range(len(rows)), key=lambda i: -confidences[i])
    print("\nPar niveau de confiance")
    for level in COVERAGE_LEVELS:
        head = order[: int(len(order) * level)]
        correct = sum(predicted[i] == expected[i] for i in head)
        print(f"  {level:.0%} plus confiants : {correct / len(head):.1%}")

    per_class: dict[int, list[int]] = defaultdict(lambda: [0, 0])
    confusions: Counter = Counter()
    for p, e in zip(predicted, expected):
        per_class[e][1] += 1
        if p == e:
            per_class[e][0] += 1
        else:
            confusions[(LABELS[e], LABELS[p])] += 1

    weakest = sorted(
        ((slug, ok, total) for slug, (ok, total) in per_class.items() if total >= MIN_CLASS_SIZE),
        key=lambda row: row[1] / row[2],
    )
    print(f"\nClasses les plus faibles (n ≥ {MIN_CLASS_SIZE})")
    for index, ok, total in weakest[:WEAKEST_CLASSES]:
        print(f"  {LABELS[index]:36s} {ok / total:5.1%}  ({ok}/{total})")

    print("\nConfusions dominantes")
    for (expected_slug, predicted_slug), count in confusions.most_common(TOP_CONFUSIONS):
        print(f"  {count:5d}  {expected_slug:32s} → {predicted_slug}")


if __name__ == "__main__":
    main()
