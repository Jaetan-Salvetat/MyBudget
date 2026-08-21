import json
import random
from pathlib import Path

from examples import EXAMPLES

ROOT = Path(__file__).resolve().parents[2]
TAXONOMY_PATH = ROOT / "assets" / "categories.json"
DATASET_DIR = Path(__file__).parent / "dataset"
SEED = 42
TRAIN_RATIO = 0.85
EXPENSE_SECTION = "expenses"
INCOME_SECTION = "income"


def load_labels() -> tuple[list[str], int]:
    """Return the ordered taxonomy slugs and the number of expense classes.

    The order is the contract with the ONNX model: it must match
    QuickAddLabels.categories on the app side.
    """
    taxonomy = json.loads(TAXONOMY_PATH.read_text(encoding="utf-8"))
    labels: list[str] = []
    num_expense = 0
    for section in (EXPENSE_SECTION, INCOME_SECTION):
        for group, body in taxonomy[section].items():
            for subcategory in body["subcategories"]:
                labels.append(f"{group}.{subcategory}")
        if section == EXPENSE_SECTION:
            num_expense = len(labels)
    return labels, num_expense


LABELS, NUM_EXPENSE = load_labels()
NUM_INCOME = len(LABELS) - NUM_EXPENSE


def validate_coverage() -> None:
    missing = [slug for slug in LABELS if not EXAMPLES.get(slug)]
    unknown = [slug for slug in EXAMPLES if slug not in LABELS]
    if missing:
        raise ValueError(f"Slugs sans exemples : {missing}")
    if unknown:
        raise ValueError(f"Exemples pour des slugs inconnus : {unknown}")


TIME_SUFFIXES: list[str] = [
    "hier", "ce matin", "ce soir", "lundi", "mardi",
    "mercredi", "jeudi", "vendredi", "samedi", "dimanche",
    "la semaine dernière", "le mois dernier", "aujourd'hui",
    "en janvier", "en février", "en mars", "en avril",
    "en mai", "en juin", "en juillet", "en août",
    "en septembre", "en octobre", "en novembre", "en décembre",
]

EXPENSE_PREFIXES: list[str] = [
    "payé", "acheté", "pris", "réglé", "dépensé pour",
    "payer", "achat", "dépense",
]

INCOME_PREFIXES: list[str] = [
    "reçu", "perçu", "touché", "encaissé", "gagné",
]

CONTEXT_SUFFIXES: list[str] = [
    "avec les amis", "pour moi", "en famille", "pour le boulot",
    "du mois", "du week-end", "de la semaine", "pour la maison",
    "en ligne", "en magasin", "sur place", "à emporter",
]


def make_sample(text: str, type_label: int, cat_label: int, rec_label: int) -> dict:
    return {
        "text": text.strip(),
        "type_label": type_label,
        "category_label": cat_label,
        "recurrence_label": rec_label,
    }


CASUAL_WRAPPERS: list[str] = [
    "j'ai {prefix} {text}",
    "{text} rapide",
    "petit {text}",
    "{text} pas cher",
    "{text} en promo",
    "{text} urgent",
]


def augment(text: str, type_label: int, rec: int, rng: random.Random) -> list[tuple[str, int]]:
    """Generate 6-10 augmented variants per base example."""
    variants: list[tuple[str, int]] = []

    variants.append((text.lower(), rec))

    suffix = rng.choice(TIME_SUFFIXES)
    variants.append((f"{text} {suffix}", rec))

    if type_label == 0:
        prefix = rng.choice(EXPENSE_PREFIXES)
    else:
        prefix = rng.choice(INCOME_PREFIXES)
    variants.append((f"{prefix} {text}", rec))

    suffix2 = rng.choice(TIME_SUFFIXES)
    if type_label == 0:
        prefix2 = rng.choice(EXPENSE_PREFIXES)
    else:
        prefix2 = rng.choice(INCOME_PREFIXES)
    variants.append((f"{prefix2} {text} {suffix2}", rec))

    ctx = rng.choice(CONTEXT_SUFFIXES)
    variants.append((f"{text} {ctx}", rec))

    suffix3 = rng.choice(TIME_SUFFIXES)
    variants.append((f"{text.lower()} {suffix3}", rec))

    ctx2 = rng.choice(CONTEXT_SUFFIXES)
    suffix4 = rng.choice(TIME_SUFFIXES)
    variants.append((f"{text} {ctx2} {suffix4}", rec))

    if type_label == 0 and rng.random() < 0.6:
        wrapper = rng.choice(CASUAL_WRAPPERS)
        pref = rng.choice(EXPENSE_PREFIXES)
        variants.append((wrapper.format(prefix=pref, text=text.lower()), rec))

    if rng.random() < 0.5:
        if type_label == 0:
            prefix3 = rng.choice(EXPENSE_PREFIXES)
        else:
            prefix3 = rng.choice(INCOME_PREFIXES)
        ctx3 = rng.choice(CONTEXT_SUFFIXES)
        variants.append((f"{prefix3} {text.lower()} {ctx3}", rec))

    return variants


def generate(seed: int = SEED) -> tuple[list[dict], list[dict]]:
    validate_coverage()
    rng = random.Random(seed)
    all_samples: list[dict] = []

    for cat_idx, slug in enumerate(LABELS):
        type_label = 0 if cat_idx < NUM_EXPENSE else 1

        for text, rec in EXAMPLES[slug]:
            all_samples.append(make_sample(text, type_label, cat_idx, rec))

            for aug_text, aug_rec in augment(text, type_label, rec, rng):
                all_samples.append(make_sample(aug_text, type_label, cat_idx, aug_rec))

    rng.shuffle(all_samples)
    split = int(len(all_samples) * TRAIN_RATIO)
    return all_samples[:split], all_samples[split:]


def save_jsonl(data: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for row in data:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


def main() -> None:
    train, eval_ = generate()

    save_jsonl(train, DATASET_DIR / "train.jsonl")
    save_jsonl(eval_, DATASET_DIR / "eval.jsonl")

    type_counts = [0, 0]
    rec_counts = [0, 0]
    cat_counts: dict[int, int] = {}
    for sample in train:
        type_counts[sample["type_label"]] += 1
        rec_counts[sample["recurrence_label"]] += 1
        cat_counts[sample["category_label"]] = cat_counts.get(sample["category_label"], 0) + 1

    ranked = sorted(cat_counts.items(), key=lambda item: item[1])
    print(f"Classes: {len(LABELS)} ({NUM_EXPENSE} depenses + {NUM_INCOME} revenus)")
    print(f"Train: {len(train)}  |  Eval: {len(eval_)}")
    print(f"Type (train): expense={type_counts[0]}, income={type_counts[1]}")
    print(f"Recurrence (train): ponctuel={rec_counts[0]}, fixe={rec_counts[1]}")
    print("Moins representees : " + ", ".join(f"{LABELS[i]}={n}" for i, n in ranked[:5]))
    print("Plus representees  : " + ", ".join(f"{LABELS[i]}={n}" for i, n in ranked[-5:]))


if __name__ == "__main__":
    main()
