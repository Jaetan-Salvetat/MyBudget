"""Features par mot, pour décider quels mots d'une ligne forment le libellé.

`line_features_all` décrit une ligne entière : il sait dire qu'une ligne est
un article, jamais où le nom de cet article commence. Or c'est là que se
concentrent les libellés faux — un code article collé devant, une quantité ou
un prix unitaire collés derrière, sur la bonne ligne.

Les règles répondaient par une coupe verticale unique, le quantile 0,9 des
prix. Un ticket imprime trois à cinq colonnes — code, libellé, quantité, prix
unitaire, prix — et leurs frontières changent d'une enseigne à l'autre : une
coupe scalaire ne peut pas les exprimer.

La colonne devient donc une **feature par mot**. Un mot dont la bande
verticale est occupée, sur les autres lignes du ticket, par des nombres
appartient à une colonne ; le même mot ailleurs appartient au nom. C'est ce
que la coupe unique ne pouvait pas voir, et c'est ce qui sépare « SANDW » de
« SANDW 6015 ».
"""

from __future__ import annotations

import re

from reference.line_signals import hashed_trigrams
from reference.lines import PhysicalLine, Word
from reference.structure import (
    PRICE_PATTERN,
    QUANTITY_PATTERN,
    WEIGHT_PATTERN,
    _rightmost_price,
    merge_price_fragments,
)

NEIGHBOUR_ABSENT = -1.0

# Unités imprimées à côté d'une quantité ou d'un prix au kilo : elles bornent
# le libellé sans en faire partie.
UNIT_PATTERN = re.compile(r"^(KG|G|GR|L|CL|ML|PCE|PC|U|UN|EUR|€)$", re.IGNORECASE)
COUNT_PATTERN = re.compile(r"^\d{1,3}\s?[xX*]$|^[xX*]\s?\d{1,3}$")
CURRENCY = re.compile(r"[€$]|\bEUR\b", re.IGNORECASE)

# Trigrammes du mot, chiffres masqués : ce que le mot *dit*, quand sa forme et
# sa position ne suffisent pas — « TVA », « kg », « REMISE ».
TRIGRAM_BUCKETS = 16

FEATURE_NAMES = [
    "left_ratio",
    "right_ratio",
    "width_ratio",
    "height_ratio",
    "word_index_ratio",
    "is_first",
    "is_last",
    "word_count",
    "gap_before",
    "gap_after",
    "line_position",
    "char_count",
    "digit_ratio",
    "alpha_ratio",
    "upper_ratio",
    "is_pure_digits",
    "is_price_shaped",
    "is_count",
    "is_unit",
    "has_currency",
    "confidence",
    "is_price_word",
    "after_price",
    "dist_to_price",
    "band_fill",
    "band_digit_ratio",
    "band_alpha_ratio",
    "band_price_ratio",
    "line_has_price",
    "line_digit_ratio",
    "line_word_count_ratio",
    *[f"tri_{bucket}" for bucket in range(TRIGRAM_BUCKETS)],
]


def _shape(text: str) -> tuple[float, float, float]:
    chars = len(text)
    if not chars:
        return 0.0, 0.0, 0.0
    return (
        sum(char.isdigit() for char in text) / chars,
        sum(char.isalpha() for char in text) / chars,
        sum(char.isupper() for char in text) / chars,
    )


def _is_price_shaped(text: str) -> bool:
    return bool(PRICE_PATTERN.match(text.replace("€", "").replace("EUR", "").strip()))


def _band_words(lines: list[PhysicalLine], row: int, centre: float) -> list[Word]:
    """Les mots que les *autres* lignes impriment à cette abscisse."""
    found = []
    for index, line in enumerate(lines):
        if index == row:
            continue
        for word in line.words:
            if word.left <= centre <= word.right:
                found.append(word)
                break
    return found


def _price_word(line: PhysicalLine) -> Word | None:
    """Le mot qui porte le prix de la ligne, fragments recollés.

    Le prix se cherche sur la ligne fusionnée — l'OCR coupe « 2,95 » au
    séparateur — mais le repère rendu est une abscisse, valable dans les deux
    découpages."""
    priced = _rightmost_price(merge_price_fragments(line))
    return priced[1] if priced is not None else None


def featurize(lines: list[PhysicalLine]) -> list[list[list[float]]]:
    """Un vecteur de features par mot, ligne par ligne, dans l'ordre du
    ticket."""
    if not lines:
        return []
    words = [word for line in lines for word in line.words]
    if not words:
        return [[] for _ in lines]
    left = min(word.left for word in words)
    width = (max(word.right for word in words) - left) or 1.0
    heights = sorted(word.bottom - word.top for word in words)
    median_height = heights[len(heights) // 2] or 1.0
    max_words = max(len(line.words) for line in lines) or 1
    price_words = [_price_word(line) for line in lines]

    rows = []
    for row, line in enumerate(lines):
        price = price_words[row]
        line_digits, _, _ = _shape(line.text)
        line_left = min((word.left for word in line.words), default=left)
        line_right = max((word.right for word in line.words), default=left + width)
        line_width = (line_right - line_left) or 1.0
        vectors = []
        for position, word in enumerate(line.words):
            digit_ratio, alpha_ratio, upper_ratio = _shape(word.text)
            centre = (word.left + word.right) / 2
            band = _band_words(lines, row, centre)
            band_shapes = [_shape(other.text) for other in band]
            previous = line.words[position - 1] if position else None
            following = (
                line.words[position + 1] if position + 1 < len(line.words) else None
            )
            vectors.append(
                [
                    (word.left - left) / width,
                    (word.right - left) / width,
                    (word.right - word.left) / width,
                    (word.bottom - word.top) / median_height,
                    position / len(line.words),
                    float(position == 0),
                    float(position == len(line.words) - 1),
                    float(len(line.words)),
                    (word.left - previous.right) / width
                    if previous
                    else NEIGHBOUR_ABSENT,
                    (following.left - word.right) / width
                    if following
                    else NEIGHBOUR_ABSENT,
                    (word.left - line_left) / line_width,
                    float(len(word.text)),
                    digit_ratio,
                    alpha_ratio,
                    upper_ratio,
                    float(word.text.isdigit()),
                    float(_is_price_shaped(word.text)),
                    float(
                        bool(
                            COUNT_PATTERN.match(word.text)
                            or QUANTITY_PATTERN.match(word.text)
                            or WEIGHT_PATTERN.match(word.text)
                        )
                    ),
                    float(bool(UNIT_PATTERN.match(word.text))),
                    float(bool(CURRENCY.search(word.text))),
                    word.confidence
                    if word.confidence is not None
                    else NEIGHBOUR_ABSENT,
                    float(
                        price is not None
                        and word.left < price.right
                        and word.right > price.left
                    ),
                    float(price is not None and word.left >= price.right),
                    (price.left - word.right) / width
                    if price is not None
                    else NEIGHBOUR_ABSENT,
                    len(band) / (len(lines) - 1) if len(lines) > 1 else 0.0,
                    sum(shape[0] for shape in band_shapes) / len(band) if band else 0.0,
                    sum(shape[1] for shape in band_shapes) / len(band) if band else 0.0,
                    sum(_is_price_shaped(other.text) for other in band) / len(band)
                    if band
                    else 0.0,
                    float(price is not None),
                    line_digits,
                    len(line.words) / max_words,
                    *hashed_trigrams(word.text, TRIGRAM_BUCKETS),
                ]
            )
        rows.append(vectors)
    return rows
