"""Construit le corpus d'entraînement à partir des exemples curés et des entités.

Deux garde-fous portent la qualité du dataset :

- la coupe train/eval se fait par entité, pas par échantillon. Une même marque
  déclinée en dix phrases ne peut pas se retrouver des deux côtés, sinon
  l'évaluation mesure la mémoire et non la généralisation ;
- chaque classe reçoit un budget d'exemples borné en haut et en bas. Sans cela
  les 4 800 compagnies aériennes écrasent les dix libellés de pension
  alimentaire.
"""

import json
import random
from collections import defaultdict
from pathlib import Path

from corpus.quick_add.examples import EXAMPLES
from knowledge.build import SOURCE_PRIORITY
from knowledge.entities import TIER_HEAD, Entity, normalize, read_entities
from paths import DATASET_DIR, ENTITIES_PATH
from taxonomy import ACTIVE_LABELS, LABELS, NUM_EXPENSE, RECURRING, type_of

SEED = 42
EVAL_ENTITY_RATIO = 0.08
CLASS_SAMPLE_CAP = 6000
CLASS_SAMPLE_FLOOR = 900
CURATED_SOURCE = "curated"
AMOUNT_RATIO = 0.15

NUM_INCOME = len(LABELS) - NUM_EXPENSE

FR_EXPENSE_PREFIXES = [
    "payé", "acheté", "pris", "réglé", "dépensé pour", "commandé", "j'ai payé",
    "j'ai acheté", "achat", "dépense", "note de", "facture",
]
FR_INCOME_PREFIXES = [
    "reçu", "perçu", "touché", "encaissé", "gagné", "viré", "j'ai reçu", "virement",
]
FR_SUFFIXES = [
    "hier", "ce matin", "ce soir", "lundi", "mardi", "mercredi", "jeudi", "vendredi",
    "samedi", "dimanche", "la semaine dernière", "le mois dernier", "aujourd'hui",
    "ce week-end", "en janvier", "en février", "en mars", "en avril", "en mai",
    "en juin", "en juillet", "en août", "en septembre", "en octobre", "en novembre",
    "en décembre",
]
FR_CONTEXTS = [
    "avec les amis", "pour moi", "en famille", "pour le boulot", "du mois",
    "du week-end", "de la semaine", "pour la maison", "en ligne", "en magasin",
    "sur place", "à emporter", "avec les collègues", "pour les enfants",
]

EN_EXPENSE_PREFIXES = [
    "paid for", "bought", "spent on", "picked up", "ordered", "got", "payment for",
    "purchase", "bill for", "paid",
]
EN_INCOME_PREFIXES = [
    "received", "got paid", "earned", "refunded", "payment received", "transfer from",
]
EN_SUFFIXES = [
    "yesterday", "this morning", "tonight", "last night", "on monday", "on tuesday",
    "on wednesday", "on thursday", "on friday", "on saturday", "on sunday",
    "last week", "last month", "today", "this weekend", "in january", "in february",
    "in march", "in april", "in may", "in june", "in july", "in august",
    "in september", "in october", "in november", "in december",
]
EN_CONTEXTS = [
    "with friends", "for work", "for the house", "for the kids", "online",
    "in store", "for the month", "for the weekend", "takeaway", "with the family",
]

AMOUNTS = [
    "12", "8,50", "8.50", "4€", "€25", "15 euros", "30 balles", "£15", "$20",
    "1200", "45,90", "3.20", "9,99", "60", "250", "12 quid", "22.40",
]

FRENCH_WRAPPERS = ["petit {text}", "{text} rapide", "{text} pas cher", "{text} en promo"]
ENGLISH_WRAPPERS = ["quick {text}", "cheap {text}", "{text} on sale", "small {text}"]

# « abonnement X » est un prélèvement quelle que soit la classe de X : la
# récurrence se lit dans la formulation, pas seulement dans la nature du
# marchand. Sans cette règle, « abonnement salle de sport » restait ponctuel
# parce que les salles de sport sont majoritairement des achats uniques.
FRENCH_RECURRING_WRAPPERS = [
    "abonnement {text}", "{text} mensuel", "{text} tous les mois", "cotisation {text}",
    "prélèvement {text}", "échéance {text}", "{text} du mois", "abo {text}",
]
ENGLISH_RECURRING_WRAPPERS = [
    "{text} subscription", "monthly {text}", "{text} membership", "{text} plan",
    "{text} direct debit", "{text} every month", "monthly {text} payment",
]
RECURRING_RATIO = 0.18


def _forms_budget(entity: Entity) -> int:
    priority = SOURCE_PRIORITY.get(entity.source, 0)
    if entity.source == CURATED_SOURCE:
        return 9
    if priority >= 4:
        return 8
    if priority == 3:
        return 5 if entity.tier == TIER_HEAD else 3
    if priority == 2:
        return 3 if entity.tier == TIER_HEAD else 2
    return 2


def _rank(entity: Entity) -> tuple[int, int]:
    if entity.source == CURATED_SOURCE:
        return 6, entity.tier
    return SOURCE_PRIORITY.get(entity.source, 0), entity.tier


def _decorate(text: str, is_income: bool, english: bool, rng: random.Random) -> tuple[str, bool]:
    prefixes = (EN_INCOME_PREFIXES if is_income else EN_EXPENSE_PREFIXES) if english else (
        FR_INCOME_PREFIXES if is_income else FR_EXPENSE_PREFIXES
    )
    suffixes = EN_SUFFIXES if english else FR_SUFFIXES
    contexts = EN_CONTEXTS if english else FR_CONTEXTS
    wrappers = ENGLISH_WRAPPERS if english else FRENCH_WRAPPERS

    if rng.random() < RECURRING_RATIO:
        wrapper = rng.choice(ENGLISH_RECURRING_WRAPPERS if english else FRENCH_RECURRING_WRAPPERS)
        return wrapper.format(text=text.lower()), True

    shape = rng.randrange(7)
    if shape == 0:
        out = text.lower()
    elif shape == 1:
        out = f"{text} {rng.choice(suffixes)}"
    elif shape == 2:
        out = f"{rng.choice(prefixes)} {text.lower()}"
    elif shape == 3:
        out = f"{rng.choice(prefixes)} {text.lower()} {rng.choice(suffixes)}"
    elif shape == 4:
        out = f"{text} {rng.choice(contexts)}"
    elif shape == 5:
        out = rng.choice(wrappers).format(text=text.lower())
    else:
        out = f"{text.lower()} {rng.choice(contexts)} {rng.choice(suffixes)}"

    if rng.random() < AMOUNT_RATIO:
        out = f"{out} {rng.choice(AMOUNTS)}"
    return out, False


def _surface_forms(
    entity: Entity, budget: int, rng: random.Random
) -> list[tuple[str, int]]:
    """Le nom nu d'abord : c'est la forme que l'utilisateur tape le plus."""
    forms: list[tuple[str, int]] = []
    seen: set[str] = set()

    def push(text: str, recurrence: int) -> None:
        cleaned = " ".join(text.split())
        key = normalize(cleaned)
        if cleaned and key not in seen:
            seen.add(key)
            forms.append((cleaned, recurrence))

    surfaces = entity.surfaces
    for surface in surfaces[:3]:
        push(surface, entity.recurrence)

    is_income = type_of(entity.slug) == 1
    attempts = 0
    while len(forms) < budget and attempts < budget * 4:
        attempts += 1
        base = rng.choice(surfaces)
        text, marked = _decorate(base, is_income, attempts % 2 == 1, rng)
        push(text, RECURRING if marked else entity.recurrence)
    return forms[:budget]


def _curated_entities() -> list[Entity]:
    """Les exemples écrits à la main, promus au rang d'entités prioritaires."""
    out: list[Entity] = []
    for slug, rows in EXAMPLES.items():
        for text, recurrence in rows:
            out.append(
                Entity(
                    name=text,
                    slug=slug,
                    source=CURATED_SOURCE,
                    tier=TIER_HEAD,
                    recurrence=recurrence,
                )
            )
    return out


def load_entities() -> list[Entity]:
    if not ENTITIES_PATH.exists():
        raise FileNotFoundError(
            f"{ENTITIES_PATH} absent : lancer d'abord `python -m knowledge.build`"
        )
    return _curated_entities() + list(read_entities(ENTITIES_PATH))


def validate_coverage(entities: list[Entity]) -> None:
    covered = {entity.slug for entity in entities}
    missing = [slug for slug in ACTIVE_LABELS if slug not in covered]
    if missing:
        raise ValueError(f"Classes sans aucune entité : {missing}")


def _group(entities: list[Entity]) -> dict[str, list[Entity]]:
    grouped: dict[str, list[Entity]] = defaultdict(list)
    for entity in entities:
        grouped[entity.slug].append(entity)
    return grouped


def _split_entities(
    entities: list[Entity], rng: random.Random
) -> tuple[list[Entity], list[Entity]]:
    """La coupe se fait sur les entités pour qu'aucun nom ne traverse."""
    train: list[Entity] = []
    held_out: list[Entity] = []
    for slug_entities in _group(entities).values():
        pool = sorted(slug_entities, key=lambda e: e.key)
        rng.shuffle(pool)
        count = int(len(pool) * EVAL_ENTITY_RATIO)
        keep = max(0, min(count, len(pool) - 1))
        held_out.extend(pool[:keep])
        train.extend(pool[keep:])
    return train, held_out


def _samples_for_class(
    slug: str, slug_entities: list[Entity], rng: random.Random, cap: int, floor: int
) -> list[dict]:
    index = LABELS.index(slug)
    type_label = type_of(slug)
    ordered = sorted(slug_entities, key=_rank, reverse=True)

    rows: list[dict] = []
    seen: set[str] = set()

    def emit(entity: Entity, budget: int) -> None:
        for text, recurrence in _surface_forms(entity, budget, rng):
            key = normalize(text)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "text": text,
                    "type_label": type_label,
                    "category_label": index,
                    "recurrence_label": recurrence,
                }
            )

    remaining = cap
    for entity in ordered:
        budget = _forms_budget(entity) if remaining > 0 else 1
        emit(entity, min(budget, max(1, remaining)))
        remaining = cap - len(rows)
        if remaining <= 0:
            break

    rounds = 0
    while len(rows) < floor and rounds < 12:
        rounds += 1
        for entity in ordered:
            if len(rows) >= floor:
                break
            emit(entity, 3)
    return rows[:cap]


def generate(seed: int = SEED) -> tuple[list[dict], list[dict]]:
    rng = random.Random(seed)
    entities = load_entities()
    validate_coverage(entities)

    train_entities, held_out = _split_entities(entities, rng)
    train_groups = _group(train_entities)
    eval_groups = _group(held_out)

    train: list[dict] = []
    for slug, group in train_groups.items():
        train.extend(_samples_for_class(slug, group, rng, CLASS_SAMPLE_CAP, CLASS_SAMPLE_FLOOR))

    evaluation: list[dict] = []
    for slug, group in eval_groups.items():
        evaluation.extend(_samples_for_class(slug, group, rng, 400, 0))

    rng.shuffle(train)
    rng.shuffle(evaluation)
    return train, evaluation


def save_jsonl(rows: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")


def main() -> None:
    train, evaluation = generate()
    save_jsonl(train, DATASET_DIR / "train.jsonl")
    save_jsonl(evaluation, DATASET_DIR / "eval.jsonl")

    per_class = defaultdict(int)
    types = [0, 0]
    recurrences = [0, 0]
    for row in train:
        per_class[row["category_label"]] += 1
        types[row["type_label"]] += 1
        recurrences[row["recurrence_label"]] += 1

    ranked = sorted(per_class.items(), key=lambda item: item[1])
    print(f"Classes : {len(LABELS)} ({NUM_EXPENSE} dépenses + {NUM_INCOME} revenus)")
    print(f"Train : {len(train)}  |  Eval (entités jamais vues) : {len(evaluation)}")
    print(f"Type : dépense={types[0]}, revenu={types[1]}")
    print(f"Récurrence : ponctuel={recurrences[0]}, fixe={recurrences[1]}")
    print("Moins représentées : " + ", ".join(f"{LABELS[i]}={n}" for i, n in ranked[:5]))
    print("Plus représentées  : " + ", ".join(f"{LABELS[i]}={n}" for i, n in ranked[-5:]))


if __name__ == "__main__":
    main()
