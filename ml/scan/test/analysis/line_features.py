"""Features par ligne porteuse de prix, pour le classifieur de lignes V2.

Uniquement des mesures déterministes et portables en Dart : géométrie,
lexiques, formes de texte. La ligne est décrite avec son contexte (ligne
précédente / suivante), car le rôle d'un montant dépend de son voisinage
(un prix sous un libellé seul n'est pas un prix de table TVA).
"""

from __future__ import annotations

import re

from lines import PhysicalLine
from structure import (
    DISCOUNT_WORDS,
    PAYMENT_WORDS,
    QUANTITY_PATTERN,
    STOP_WORDS,
    SUBTOTAL_WORDS,
    TOTAL_WORDS,
    TVA_WORDS,
    WEIGHT_PATTERN,
    _contains,
    _is_detail_line,
    _rightmost_price,
    merge_price_fragments,
    parse_price,
)

FEATURE_NAMES = [
    "price_value",
    "price_negative",
    "price_round",
    "price_rel_right",
    "price_rel_left",
    "rel_position",
    "n_prices",
    "n_words",
    "n_letters",
    "n_digits",
    "label_letters",
    "label_has_percent",
    "label_is_detail",
    "label_quantity",
    "has_barcode_token",
    "lex_total",
    "lex_subtotal",
    "lex_discount",
    "lex_payment",
    "lex_tva",
    "lex_stop",
    "starts_discount_word",
    "after_last_total",
    "is_last_priced",
    "price_is_max",
    "prev_has_price",
    "prev_lex_total",
    "prev_lex_stop",
    "prev_is_name_only",
    "next_has_price",
    "next_lex_total",
    "next_starts_discount",
]

BARCODE_PATTERN = re.compile(r"\b\d{8,14}\b")


class PricedLine:
    """Une ligne fusionnée porteuse d'un prix, prête à featurer."""

    def __init__(self, index: int, line: PhysicalLine, price: float, word):
        self.index = index
        self.line = line
        self.price = price
        self.word = word

    @property
    def label(self) -> str:
        return " ".join(
            w.text for w in self.line.words if w is not self.word
        ).strip()


def priced_lines(merged: list[PhysicalLine]) -> list[PricedLine]:
    result = []
    for index, line in enumerate(merged):
        priced = _rightmost_price(line)
        if priced is not None:
            result.append(PricedLine(index, line, priced[0], priced[1]))
    return result


def _page_width(merged: list[PhysicalLine]) -> float:
    rights = [w.right for line in merged for w in line.words]
    return max(rights) if rights else 1.0


def _last_total_index(merged: list[PhysicalLine]) -> int:
    last = -1
    for index, line in enumerate(merged):
        if _contains(line.text, TOTAL_WORDS):
            last = index
    return last


def featurize(merged: list[PhysicalLine]) -> tuple[list[PricedLine], list[list[float]]]:
    lines = priced_lines(merged)
    if not lines:
        return [], []
    width = _page_width(merged)
    total_index = _last_total_index(merged)
    max_price = max(abs(p.price) for p in lines)
    rows = []
    for rank, priced in enumerate(lines):
        line, price, word = priced.line, priced.price, priced.word
        text = line.text
        label = priced.label
        compact_label = re.sub(r"EUR|[€]|\s+", "", label)
        prev_line = merged[priced.index - 1] if priced.index > 0 else None
        next_line = (
            merged[priced.index + 1]
            if priced.index + 1 < len(merged)
            else None
        )
        prices_in_line = [
            p for w in line.words if (p := parse_price(w.text)) is not None
        ]
        rows.append([
            min(abs(price), 500.0),
            1.0 if price < 0 else 0.0,
            1.0 if abs(price * 100) % 10 < 0.5 else 0.0,
            word.right / width,
            word.left / width,
            priced.index / max(len(merged) - 1, 1),
            float(len(prices_in_line)),
            float(len(line.words)),
            float(sum(c.isalpha() for c in text)),
            float(sum(c.isdigit() for c in text)),
            float(sum(c.isalpha() for c in label)),
            1.0 if "%" in label else 0.0,
            1.0 if _is_detail_line(label) else 0.0,
            1.0
            if QUANTITY_PATTERN.match(compact_label)
            or WEIGHT_PATTERN.match(compact_label)
            else 0.0,
            1.0 if BARCODE_PATTERN.search(label) else 0.0,
            1.0 if _contains(text, TOTAL_WORDS) else 0.0,
            1.0 if _contains(text, SUBTOTAL_WORDS) else 0.0,
            1.0 if _contains(text, DISCOUNT_WORDS) else 0.0,
            1.0 if _contains(text, PAYMENT_WORDS) else 0.0,
            1.0 if _contains(text, TVA_WORDS) else 0.0,
            1.0 if _contains(text, STOP_WORDS) else 0.0,
            1.0 if label.strip().upper().startswith(DISCOUNT_WORDS) else 0.0,
            1.0 if total_index >= 0 and priced.index > total_index else 0.0,
            1.0 if rank == len(lines) - 1 else 0.0,
            1.0 if abs(abs(price) - max_price) < 0.005 else 0.0,
            _flag(prev_line, lambda l: _rightmost_price(l) is not None),
            _flag(prev_line, lambda l: _contains(l.text, TOTAL_WORDS)),
            _flag(prev_line, lambda l: _contains(l.text, STOP_WORDS)),
            _flag(prev_line, _is_name_only),
            _flag(next_line, lambda l: _rightmost_price(l) is not None),
            _flag(next_line, lambda l: _contains(l.text, TOTAL_WORDS)),
            _flag(
                next_line,
                lambda l: l.text.strip().upper().startswith(DISCOUNT_WORDS),
            ),
        ])
    return lines, rows


def _flag(line: PhysicalLine | None, predicate) -> float:
    if line is None:
        return 0.0
    return 1.0 if predicate(line) else 0.0


def _is_name_only(line: PhysicalLine) -> bool:
    if _rightmost_price(line) is not None:
        return False
    letters = sum(c.isalpha() for c in line.text)
    return letters >= 2 and not _contains(line.text, STOP_WORDS)


def merged_lines(raw_lines: list[PhysicalLine]) -> list[PhysicalLine]:
    return [merge_price_fragments(line) for line in raw_lines]
