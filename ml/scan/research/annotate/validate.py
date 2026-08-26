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

Le verdict est typé. Une seule cause de rejet laisse le ticket servir au
tagger de rôles, et la distinguer par un enum plutôt que par le texte du
message évite qu'une reformulation change silencieusement le corpus.

Les entrées sont positionnelles : l'entrée `i` décrit la ligne `i`. Le
retour du modèle, lui, est indexé — `prompt.positional` le remet dans cet
ordre avant que le filtre ne le voie.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from enum import StrEnum

from annotate.schema import DISCOUNT, ITEM, ROLES, SUBTOTAL, TOTAL
from reference.lines import PhysicalLine
from reference.structure import merge_price_fragments, parse_price

TOLERANCE = 0.005


class Cause(StrEnum):
    """Pourquoi une annotation n'entre pas dans le corpus."""

    MALFORMED = "annotation malformée"
    UNREADABLE_AMOUNT = "montant illisible sur sa ligne"
    NO_ITEM = "aucun article"
    NO_REFERENCE = "aucune référence (total ou sous-total)"
    SUM_MISMATCH = "somme ≠ référence imprimée"


@dataclass(frozen=True)
class Rejection:
    cause: Cause
    detail: str = ""

    def __str__(self) -> str:
        return f"{self.cause} : {self.detail}" if self.detail else str(self.cause)


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


def rejection(
    entries: list[dict], lines: list[PhysicalLine]
) -> Rejection | None:
    """Le verdict du filtre, ou None quand l'annotation entre dans le corpus."""
    if len(entries) != len(lines):
        return Rejection(
            Cause.MALFORMED, f"{len(entries)} lignes annotées pour {len(lines)} lues"
        )

    # Le pipeline recolle les prix coupés au séparateur décimal avant de
    # lire quoi que ce soit : le filtre doit juger la même ligne que lui.
    merged = [merge_price_fragments(line) for line in lines]

    for index, entry in enumerate(entries):
        if entry.get("role") not in ROLES:
            return Rejection(Cause.MALFORMED, f"rôle inconnu : {entry.get('role')}")
        for amount in _entry_amounts(entry):
            if not _readable(amount, merged[index]):
                return Rejection(
                    Cause.UNREADABLE_AMOUNT, f"montant {amount} ligne {index}"
                )

    items_sum, references, item_count = _sum_and_references(entries)
    if item_count == 0:
        return Rejection(Cause.NO_ITEM)
    if not references:
        return Rejection(Cause.NO_REFERENCE)
    # Le total TTC en Europe, le sous-total hors taxe aux États-Unis : le
    # checksum du flow accepte l'un ou l'autre, le filtre aussi.
    if any(abs(items_sum - reference) < TOLERANCE for reference in references):
        return None
    printed = " ou ".join(f"{reference:.2f}" for reference in references)
    return Rejection(Cause.SUM_MISMATCH, f"{items_sum:.2f} ≠ {printed}")
