"""Features de ligne, pour *toutes* les lignes d'un ticket.

`line_features_v3` ne décrit que les lignes porteuses de prix : il fallait
un prix pour calculer la plupart de ses colonnes. Or les trois postes
d'erreur les plus coûteux vivent sur des lignes sans prix — l'enseigne, la
ligne de date, et le libellé d'un article dont le prix est imprimé plus bas.
Aucun modèle ne pouvait les apprendre.

Ces features-ci ne présupposent rien : géométrie relative au ticket, forme du
texte, lexiques, et un voisinage immédiat — ce que porte la ligne d'avant et
celle d'après. Le voisinage est ce qui permet d'apprendre qu'après le total,
il n'y a plus d'articles, sans l'écrire nulle part.
"""

from __future__ import annotations

import re

from reference.line_features_v3 import hashed_trigrams
from reference.lines import PhysicalLine
from reference.structure import (
    DATE_PATTERN,
    DISCOUNT_WORDS,
    LITERAL_DATE_PATTERN,
    PAYMENT_WORDS,
    SUBTOTAL_WORDS,
    TVA_WORDS,
    _contains,
    _rightmost_price,
    contains_total,
    merge_price_fragments,
)

CHANGE_WORDS = ("RENDU", "RENDRE", "MONNAIE", "CHANGE")
COUNT_WORDS = ("ARTICLE", "ARTICLES", "NOMBRE", "QTE")
CURRENCY = re.compile(r"[€$]|\bEUR\b")
NEIGHBOUR_ABSENT = -1.0

# Fenêtre du comptage de densité, de part et d'autre de la ligne.
DENSITY_WINDOW = 3

# Trigrammes de caractères hachés du texte de la ligne, chiffres masqués.
#
# Les autres colonnes ne décrivent que la forme et la position : rien n'y dit
# ce que la ligne *raconte*. Or c'est le contenu qui sépare « PREM Litière
# AGGLO 12KG » d'une raison sociale ou d'une mention de pied — la confusion
# qui plafonne la précision d'`item_label`. Le hachage apprend cette
# distinction des données au lieu de la faire écrire dans un lexique, qu'il
# faudrait rallonger à chaque enseigne.
TRIGRAM_BUCKETS = 64

FEATURE_NAMES = [
    "rank_ratio", "top_ratio", "height_ratio", "width_ratio", "left_ratio",
    "word_count", "char_count", "digit_ratio", "alpha_ratio", "upper_ratio",
    "has_price", "price_log", "price_right_ratio", "is_negative",
    "has_date", "has_currency", "has_letters_only",
    "is_total", "is_subtotal", "is_tva", "is_payment", "is_discount",
    "is_change", "is_count",
    "prev_has_price", "next_has_price", "prev_is_total", "next_is_total",
    "prev_height_ratio", "next_height_ratio",
    "priced_rank_ratio", "after_first_total",
    # Où la ligne se situe par rapport à la zone des articles. Sans elles, une
    # ligne sans prix n'a aucune position connue dans cette zone —
    # `priced_rank_ratio` vaut -1 — et rien ne distingue le libellé d'un
    # article d'une ligne d'en-tête : c'est la confusion qui plafonnait la
    # précision d'`item_label`.
    "dist_prev_priced", "dist_next_priced", "in_priced_span", "span_position",
    "priced_density", "next_priced_not_total",
    *[f"tri_{bucket}" for bucket in range(TRIGRAM_BUCKETS)],
]



def _text_shape(text: str) -> tuple[float, float, float, int, int]:
    chars = len(text)
    if chars == 0:
        return 0.0, 0.0, 0.0, 0, 0
    digits = sum(c.isdigit() for c in text)
    alpha = sum(c.isalpha() for c in text)
    upper = sum(c.isupper() for c in text)
    return digits / chars, alpha / chars, upper / chars, chars, alpha


def _median_height(lines: list[PhysicalLine]) -> float:
    heights = sorted(line.bottom - line.top for line in lines)
    return heights[len(heights) // 2] if heights else 1.0


def _has_date(text: str) -> bool:
    compact = re.sub(r"\s+", "", text)
    return bool(DATE_PATTERN.search(compact) or LITERAL_DATE_PATTERN.search(compact))


def featurize(lines: list[PhysicalLine]) -> list[list[float]]:
    """Une ligne de features par ligne physique, dans l'ordre du ticket."""
    if not lines:
        return []
    merged = [merge_price_fragments(line) for line in lines]
    prices = [_rightmost_price(line) for line in merged]
    median_height = _median_height(merged) or 1.0
    top = min(line.top for line in merged)
    bottom = max(line.bottom for line in merged)
    span = (bottom - top) or 1.0
    left = min(word.left for line in merged for word in line.words)
    right = max(word.right for line in merged for word in line.words)
    width = (right - left) or 1.0
    totals = [contains_total(line.text) for line in merged]
    first_total = next((i for i, is_total in enumerate(totals) if is_total), len(merged))
    priced_ranks = [i for i, price in enumerate(prices) if price is not None]

    first_priced = priced_ranks[0] if priced_ranks else None
    last_priced = priced_ranks[-1] if priced_ranks else None
    priced_span = (
        (last_priced - first_priced) or 1 if priced_ranks else 1
    )

    def _distance_to_priced(index: int, step: int) -> float:
        position = index + step
        while 0 <= position < len(merged):
            if prices[position] is not None:
                return abs(position - index) / len(merged)
            position += step
        return NEIGHBOUR_ABSENT

    rows = []
    for index, line in enumerate(merged):
        text = line.text
        digit_ratio, alpha_ratio, upper_ratio, chars, alpha = _text_shape(text)
        price = prices[index]
        height = (line.bottom - line.top) / median_height
        line_left = min(word.left for word in line.words)
        line_right = max(word.right for word in line.words)

        def neighbour(offset: int, of, at: int = index) -> float:
            position = at + offset
            if not 0 <= position < len(merged):
                return NEIGHBOUR_ABSENT
            return float(of(position))

        rows.append([
            index / len(merged),
            (line.top - top) / span,
            height,
            (line_right - line_left) / width,
            (line_left - left) / width,
            float(len(line.words)),
            float(chars),
            digit_ratio,
            alpha_ratio,
            upper_ratio,
            float(price is not None),
            abs(price[0]) if price is not None else 0.0,
            (price[1].right - left) / width if price is not None else 0.0,
            float(price is not None and price[0] < 0),
            float(_has_date(text)),
            float(bool(CURRENCY.search(text))),
            float(alpha > 0 and digit_ratio == 0),
            float(totals[index]),
            float(_contains(text, SUBTOTAL_WORDS)),
            float(_contains(text, TVA_WORDS)),
            float(_contains(text, PAYMENT_WORDS)),
            float(_contains(text, DISCOUNT_WORDS)),
            float(_contains(text, CHANGE_WORDS)),
            float(_contains(text, COUNT_WORDS)),
            neighbour(-1, lambda p: prices[p] is not None),
            neighbour(+1, lambda p: prices[p] is not None),
            neighbour(-1, lambda p: totals[p]),
            neighbour(+1, lambda p: totals[p]),
            neighbour(-1, lambda p: (merged[p].bottom - merged[p].top) / median_height),
            neighbour(+1, lambda p: (merged[p].bottom - merged[p].top) / median_height),
            (priced_ranks.index(index) / len(priced_ranks)) if index in priced_ranks else NEIGHBOUR_ABSENT,
            float(index > first_total),
            _distance_to_priced(index, -1),
            _distance_to_priced(index, +1),
            float(
                first_priced is not None
                and first_priced <= index <= last_priced
            ),
            (index - first_priced) / priced_span if first_priced is not None else NEIGHBOUR_ABSENT,
            sum(
                1
                for position in range(
                    max(0, index - DENSITY_WINDOW),
                    min(len(merged), index + DENSITY_WINDOW + 1),
                )
                if prices[position] is not None
            )
            / (2 * DENSITY_WINDOW + 1),
            neighbour(
                +1, lambda p: prices[p] is not None and not totals[p]
            ),
            *hashed_trigrams(text, TRIGRAM_BUCKETS),
        ])
    return rows


# Le rattachement d'un libellé se juge sur ce que portent les lignes juste
# au-dessus du prix, pas sur la ligne seule : une fenêtre glissante donne au
# modèle les mêmes colonnes pour la ligne et ses voisines immédiates.
LINK_CONTEXT = 3


def window(rows: list[list[float]], index: int, context: int = LINK_CONTEXT) -> list[float]:
    """Les features de la ligne et des `context` lignes qui la précèdent,
    concaténées. Hors du ticket, la fenêtre est neutre."""
    width = len(rows[0]) if rows else 0
    stacked: list[float] = []
    for back in range(context + 1):
        source = index - back
        stacked.extend(rows[source] if 0 <= source < len(rows) else [0.0] * width)
    return stacked
