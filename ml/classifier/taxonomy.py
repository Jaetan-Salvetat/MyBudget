"""Chargement de la taxonomie, source de vérité des classes du modèle.

L'ordre des slugs actifs est le contrat avec l'ONNX : il doit correspondre à
QuickAddLabels.categories côté app, qui ne porte pas les slugs dépréciés.
"""

import json

from paths import TAXONOMY_PATH

EXPENSE_SECTION = "expenses"
INCOME_SECTION = "income"

EXPENSE_TYPE = 0
INCOME_TYPE = 1

ONE_TIME = 0
RECURRING = 1


def load_labels() -> tuple[list[str], int]:
    """Retourne les slugs actifs ordonnés et le nombre de classes de dépense.

    Un slug déprécié n'a plus de sortie dans le modèle : il ne vit que comme
    alias, résolu par `canonical()`."""
    taxonomy = json.loads(TAXONOMY_PATH.read_text(encoding="utf-8"))
    labels: list[str] = []
    num_expense = 0
    for section in (EXPENSE_SECTION, INCOME_SECTION):
        for group, body in taxonomy[section].items():
            for subcategory, meta in body["subcategories"].items():
                if meta.get("deprecated"):
                    continue
                labels.append(f"{group}.{subcategory}")
        if section == EXPENSE_SECTION:
            num_expense = len(labels)
    return labels, num_expense


def load_deprecated() -> dict[str, str]:
    """Slugs dépréciés et leur remplaçant, pour rediriger les anciennes sources."""
    taxonomy = json.loads(TAXONOMY_PATH.read_text(encoding="utf-8"))
    aliases: dict[str, str] = {}
    for section in (EXPENSE_SECTION, INCOME_SECTION):
        for group, body in taxonomy[section].items():
            for subcategory, meta in body["subcategories"].items():
                if meta.get("deprecated") and meta.get("alias_of"):
                    aliases[f"{group}.{subcategory}"] = meta["alias_of"]
    return aliases


LABELS, NUM_EXPENSE = load_labels()
NUM_INCOME = len(LABELS) - NUM_EXPENSE
DEPRECATED = load_deprecated()
ACTIVE_LABELS = LABELS
LABEL_INDEX = {slug: index for index, slug in enumerate(LABELS)}


def type_of(slug: str) -> int:
    """0 pour une dépense, 1 pour un revenu."""
    return EXPENSE_TYPE if LABEL_INDEX[slug] < NUM_EXPENSE else INCOME_TYPE


def canonical(slug: str) -> str:
    """Résout un slug déprécié vers son remplaçant."""
    return DEPRECATED.get(slug, slug)
