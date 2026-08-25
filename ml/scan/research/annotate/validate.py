"""Le filtre d'entrée du corpus d'entraînement.

Une annotation vient d'un modèle : elle est plausible, jamais garantie. Deux
contrôles indépendants la trient, et rien d'autre ne la protège :

1. **aucun montant inventé** — chaque montant annoté doit être lisible dans
   les mots de sa propre ligne, avec le même lecteur de prix que le
   pipeline ;
2. **le ticket porte sa propre preuve** — la somme des articles moins les
   remises doit retomber sur la référence imprimée (total, ou sous-total à
   défaut), au demi-centime.

Une annotation fausse ne franchit quasiment jamais le second contrôle : se
tromper de rôle décale la somme. C'est le même juge que le flow, appliqué
à l'annotation au lieu de l'extraction.
"""

from __future__ import annotations

import re

from annotate.schema import DISCOUNT, ITEM, ROLES, SUBTOTAL, TOTAL
from reference.lines import PhysicalLine
from reference.structure import merge_price_fragments, parse_price

TOLERANCE = 0.005
EMBEDDED_AMOUNT_PATTERN = re.compile(r"(?=(\d{1,4}[.,]\d{2}))")
MISSING_SEPARATOR_PATTERN = re.compile(r"\b(\d{1,4})\s(\d{2})\b")


def line_amounts(line: PhysicalLine) -> set[float]:
    """Les montants lisibles sur la ligne, en valeur absolue.

    Les mots que le lecteur de prix reconnaît, plus tout motif décimal
    *soudé* dans un mot : l'OCR colle régulièrement un code au prix
    (« 1911,08 » pour « 19 » et « 1,08 »), et refuser cette lecture
    jetterait des annotations correctes."""
    amounts = {
        abs(price)
        for word in line.words
        if (price := parse_price(word.text)) is not None
    }
    for match in EMBEDDED_AMOUNT_PATTERN.finditer(line.text):
        amounts.add(float(match.group(1).replace(",", ".")))
    for match in MISSING_SEPARATOR_PATTERN.finditer(line.text):
        amounts.add(float(f"{match.group(1)}.{match.group(2)}"))
    return amounts


def _readable(amount: float, line: PhysicalLine) -> bool:
    return any(abs(amount - candidate) < TOLERANCE for candidate in line_amounts(line))


def _entry_amounts(entry: dict) -> list[float]:
    return [
        value
        for key in ("amount", "discount")
        if (value := entry.get(key)) is not None
    ]


def _sum_and_references(
    entries: list[dict],
) -> tuple[float, list[float], int]:
    items_sum = 0.0
    total: float | None = None
    subtotal: float | None = None
    item_count = 0
    for entry in entries:
        amount = entry.get("amount") or 0.0
        if entry["role"] == ITEM:
            items_sum += amount - (entry.get("discount") or 0.0)
            item_count += 1
        elif entry["role"] == DISCOUNT:
            items_sum -= amount
        elif entry["role"] == TOTAL and total is None:
            total = amount
        elif entry["role"] == SUBTOTAL and subtotal is None:
            subtotal = amount
    references = [value for value in (total, subtotal) if value is not None]
    return round(items_sum, 2), references, item_count


def rejection_reason(annotation: dict, lines: list[PhysicalLine]) -> str | None:
    """La raison du rejet, ou None quand l'annotation entre dans le corpus."""
    entries = annotation.get("lines")
    if not isinstance(entries, list):
        return "pas de liste de lignes"
    if len(entries) != len(lines):
        return f"{len(entries)} lignes annotées pour {len(lines)} lues"

    # Le pipeline recolle les prix coupés au séparateur décimal avant de
    # lire quoi que ce soit : le filtre doit juger la même ligne que lui.
    merged = [merge_price_fragments(line) for line in lines]

    seen = set()
    for entry in entries:
        index = entry.get("index")
        if not isinstance(index, int) or not 0 <= index < len(lines):
            return f"index hors ticket : {index}"
        if index in seen:
            return f"index annoté deux fois : {index}"
        seen.add(index)
        if entry.get("role") not in ROLES:
            return f"rôle inconnu : {entry.get('role')}"
        for amount in _entry_amounts(entry):
            if not _readable(amount, merged[index]):
                return f"montant {amount} illisible ligne {index}"

    items_sum, references, item_count = _sum_and_references(entries)
    if item_count == 0:
        return "aucun article"
    if not references:
        return "aucune référence (total ou sous-total)"
    # Le total TTC en Europe, le sous-total hors taxe aux États-Unis : le
    # checksum du flow accepte l'un ou l'autre, le filtre aussi.
    if any(abs(items_sum - reference) < TOLERANCE for reference in references):
        return None
    printed = " ou ".join(f"{reference:.2f}" for reference in references)
    return f"somme {items_sum:.2f} ≠ référence {printed}"
