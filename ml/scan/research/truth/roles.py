"""Vérité par ligne : rôle réel de chaque ligne porteuse de prix, aligné sur
le golden.

Le golden dit exactement quels montants comptent (articles, remises, total)
: un montant absent du golden ne contribue pas au checksum, par définition.
Le sous-type des lignes non contributives (TVA, sous-total, paiement,
monnaie rendue, ligne quantité, récap remises, bruit) est descriptif —
lexiques flous et arithmétique — pour dire *quoi* le pipeline confond.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from reference.line_features import PricedLine
from reference.line_signals import (
    discount_summary,
    fuzzy_lexicon_similarity,
    tax_shaped,
)
from reference.lines import PhysicalLine
from reference.structure import (
    PAYMENT_WORDS,
    QUANTITY_PATTERN,
    SUBTOTAL_WORDS,
    TOTAL_WORDS,
    TVA_WORDS,
    WEIGHT_PATTERN,
    parse_price,
)

ITEM = "item"
DISCOUNT = "discount"
TOTAL = "total"
PAYMENT = "payment"
TVA = "tva"
SUBTOTAL = "subtotal"
QUANTITY = "quantity"
DISCOUNT_SUMMARY = "discount_summary"
CHANGE = "change"
IGNORE = "ignore"

CONTRIBUTING_ROLES = (ITEM, DISCOUNT)
REFERENCE_ROLES = (TOTAL, PAYMENT)
CHANGE_WORDS = ("RENDU", "A RENDRE", "MONNAIE", "CHANGE")
EPSILON = 0.005
LEXICON_THRESHOLD = 0.75


@dataclass(frozen=True)
class LineTruth:
    rank: int
    index: int
    price: float
    text: str
    role: str
    golden_name: str | None = None


def _cents(value: float) -> int:
    return round(float(value) * 100)


LEXICON_PRIORITY = (
    (CHANGE, CHANGE_WORDS),
    (SUBTOTAL, SUBTOTAL_WORDS),
    (TVA, TVA_WORDS),
    (PAYMENT, PAYMENT_WORDS),
    (TOTAL, TOTAL_WORDS),
)
TABLE_ROW_PRICES = 3


def _lexicon_role(text: str) -> str | None:
    """Lexique le plus proche ; à égalité, du plus spécifique au plus
    générique (« SOUS-TOTAL » contient « TOTAL »)."""
    best_role: str | None = None
    best_score = LEXICON_THRESHOLD
    for role, lexicon in LEXICON_PRIORITY:
        score = fuzzy_lexicon_similarity(text, lexicon)
        if score > best_score:
            best_role, best_score = role, score
    return best_role


def _is_table_row(priced: PricedLine) -> bool:
    prices = [parse_price(word.text) for word in priced.line.words]
    return sum(price is not None for price in prices) >= TABLE_ROW_PRICES


def _is_quantity_line(priced: PricedLine) -> bool:
    compact = re.sub(r"EUR|[€]|\s+", "", priced.label)
    return bool(QUANTITY_PATTERN.match(compact) or WEIGHT_PATTERN.match(compact))


def _non_contributing_role(
    priced: PricedLine, cents: list[int], rank: int, total_cents: int
) -> str:
    """Sous-type descriptif d'une ligne qui ne compte pas dans la somme."""
    text = priced.line.text
    lexicon = _lexicon_role(text)
    if cents[rank] < 0 and discount_summary(cents, rank):
        return DISCOUNT_SUMMARY
    if lexicon is not None:
        return lexicon
    if _is_table_row(priced):
        return TVA
    if cents[rank] == total_cents:
        return TOTAL
    if _is_quantity_line(priced):
        return QUANTITY
    if tax_shaped(cents[rank], cents):
        return TVA
    return IGNORE


def line_truth(
    merged: list[PhysicalLine], lines: list[PricedLine], golden: dict
) -> list[LineTruth]:
    receipt = golden["receipt"]
    total_cents = _cents(receipt["total"])
    remaining_items = [
        (_cents(item["amount"]), item["name"]) for item in receipt["items"]
    ]
    remaining_discounts = [
        abs(_cents(item.get("discount") or 0))
        for item in receipt["items"]
        if abs(item.get("discount") or 0) >= EPSILON
    ]
    cents = [_cents(priced.price) for priced in lines]

    roles: list[str | None] = [None] * len(lines)
    names: list[str | None] = [None] * len(lines)
    for rank, priced in enumerate(lines):
        if cents[rank] == total_cents and _lexicon_role(priced.line.text) in (
            TOTAL,
            PAYMENT,
        ):
            roles[rank] = _lexicon_role(priced.line.text)

    for rank, priced in enumerate(lines):
        if roles[rank] is not None:
            continue
        if cents[rank] < 0 and _consume_discount(remaining_discounts, cents[rank]):
            roles[rank] = DISCOUNT
            continue
        if _lexicon_role(priced.line.text) is not None or _is_quantity_line(priced):
            continue
        name = _consume_item(remaining_items, cents[rank])
        if name is not None:
            roles[rank] = ITEM
            names[rank] = name

    for rank, priced in enumerate(lines):
        if roles[rank] is not None:
            continue
        if _is_quantity_line(priced):
            name = _consume_item(remaining_items, cents[rank])
            if name is not None:
                roles[rank] = ITEM
                names[rank] = name
                continue
        roles[rank] = _non_contributing_role(priced, cents, rank, total_cents)

    return [
        LineTruth(
            rank=rank,
            index=priced.index,
            price=priced.price,
            text=priced.line.text,
            role=roles[rank] or IGNORE,
            golden_name=names[rank],
        )
        for rank, priced in enumerate(lines)
    ]


def _consume_item(remaining: list[tuple[int, str]], cents: int) -> str | None:
    for position, (amount, name) in enumerate(remaining):
        if amount == cents:
            remaining.pop(position)
            return name
    return None


def _consume_discount(remaining: list[int], cents: int) -> bool:
    for position, amount in enumerate(remaining):
        if amount == abs(cents):
            remaining.pop(position)
            return True
    return False
