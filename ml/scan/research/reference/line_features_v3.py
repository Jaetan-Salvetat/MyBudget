"""Features V3 du classifieur de lignes : V2 + signaux agnostiques au format.

Trois familles ajoutées, toutes déterministes et portables :

- **arithmétique** : un total est un prix égal à la somme d'un bloc de lignes
  au-dessus de lui ; une ligne TVA/HT est une fraction d'un autre prix ; un
  paiement duplique le total. Ces relations ne dépendent d'aucun lexique ni
  d'aucune enseigne ;
- **lexiques flous** : similarité d'édition maximale entre les mots de la
  ligne (ou des fenêtres du texte compacté) et les entrées d'un lexique —
  résiste à « Tota1 », « TOT AL », « LU.A » ;
- **forme lexicale** : trigrammes de caractères hachés du libellé, chiffres
  repliés, pour que le modèle généralise au-delà des lexiques.

Plus le contexte des lignes à prix voisines (±1 dans l'ordre des prix).
"""

from __future__ import annotations

import math
import re
import unicodedata
import zlib

from reference.line_features import FEATURE_NAMES, PricedLine
from reference.line_features import featurize as featurize_v2
from reference.lines import PhysicalLine
from reference.structure import (
    DISCOUNT_WORDS,
    PAYMENT_WORDS,
    STOP_WORDS,
    SUBTOTAL_WORDS,
    TOTAL_WORDS,
    TVA_WORDS,
    levenshtein,
)

TAX_RATES = (0.021, 0.055, 0.10, 0.20)
TAX_TOLERANCE_CENTS = 1
FUZZY_MIN_ENTRY_LENGTH = 3
FUZZY_MIN_TOKEN_LENGTH = 3
HASH_BUCKETS = 64
PRICE_RATIO_CLIP = 3.0

FUZZY_LEXICONS = {
    "fuzzy_total": TOTAL_WORDS,
    "fuzzy_subtotal": SUBTOTAL_WORDS,
    "fuzzy_discount": DISCOUNT_WORDS,
    "fuzzy_payment": PAYMENT_WORDS,
    "fuzzy_tva": TVA_WORDS,
    "fuzzy_stop": STOP_WORDS,
}

EXTRA_FEATURE_NAMES = [
    "block_sum_match",
    "discount_summary",
    "equals_prev_price",
    "equals_other_count",
    "tax_shaped",
    "price_rank_desc",
    "frac_priced_before",
    *FUZZY_LEXICONS,
    "prev_priced_fuzzy_total",
    "next_priced_fuzzy_total",
    "prev_priced_log_ratio",
    "next_priced_log_ratio",
    "prev_priced_block_sum",
    "next_priced_block_sum",
    *[f"tri_{bucket}" for bucket in range(HASH_BUCKETS)],
]

FEATURE_NAMES_V3 = [*FEATURE_NAMES, *EXTRA_FEATURE_NAMES]


def block_sum_matches(cents: list[int], index: int) -> bool:
    """Le prix `index` égale la somme signée d'un bloc contigu d'au moins
    deux lignes se terminant juste au-dessus de lui."""
    target = cents[index]
    running = 0
    for start in range(index - 1, -1, -1):
        running += cents[start]
        if index - start >= 2 and running == target:
            return True
    return False


def discount_summary(cents: list[int], index: int) -> bool:
    """Ligne négative égale à la somme d'au moins deux lignes négatives
    précédentes : récapitulatif « total des avantages », pas une remise."""
    if cents[index] >= 0:
        return False
    previous = [c for c in cents[:index] if c < 0]
    return len(previous) >= 2 and sum(previous) == cents[index]


def tax_shaped(cents: int, all_cents: list[int]) -> bool:
    """Le prix est une fraction fiscale d'un autre prix du ticket : montant
    de TVA (taux × HT ou part TVA d'un TTC) ou base HT d'un TTC."""
    if cents <= 0:
        return False
    for other in all_cents:
        if other <= 0 or other == cents:
            continue
        for rate in TAX_RATES:
            candidates = (
                other * rate,
                other * rate / (1 + rate),
                other / (1 + rate),
            )
            if any(
                abs(cents - candidate) <= TAX_TOLERANCE_CENTS
                for candidate in candidates
            ):
                return True
    return False


def _normalized(text: str) -> str:
    stripped = "".join(
        char
        for char in unicodedata.normalize("NFD", text.upper())
        if not unicodedata.combining(char)
    )
    return stripped.translate(str.maketrans("015", "OIS"))


def _similarity(candidate: str, entry: str) -> float:
    return 1.0 - levenshtein(candidate, entry) / max(len(entry), 1)


def fuzzy_lexicon_similarity(text: str, lexicon: tuple[str, ...]) -> float:
    """Similarité maximale (0..1) entre le texte et le lexique. Les entrées
    courtes (< 3 caractères) n'acceptent qu'un match exact en frontière de
    mot, comme dans les règles."""
    normalized = _normalized(text)
    tokens = [t for t in re.split(r"[^A-Z]+", normalized) if t]
    compact = "".join(tokens)
    best = 0.0
    for raw_entry in lexicon:
        entry = _normalized(raw_entry).replace(" ", "")
        if len(entry) < FUZZY_MIN_ENTRY_LENGTH:
            if re.search(rf"(?<![A-Z]){re.escape(entry)}(?![A-Z])", normalized):
                return 1.0
            continue
        for token in tokens:
            if len(token) >= FUZZY_MIN_TOKEN_LENGTH:
                best = max(best, _similarity(token, entry))
        for start in range(max(len(compact) - len(entry) + 1, 0)):
            window = compact[start : start + len(entry)]
            best = max(best, _similarity(window, entry))
        if best >= 1.0:
            return 1.0
    return best


def hashed_trigrams(text: str, buckets: int) -> list[float]:
    folded = _normalized(re.sub(r"\d", "#", text))
    folded = re.sub(r"\s+", " ", folded).strip()
    padded = f" {folded} "
    vector = [0.0] * buckets
    for start in range(max(len(padded) - 2, 0)):
        trigram = padded[start : start + 3]
        vector[zlib.crc32(trigram.encode()) % buckets] = 1.0
    return vector


def _log_ratio(current: float, other: float | None) -> float:
    if other is None or other <= 0 or current <= 0:
        return 0.0
    return max(-PRICE_RATIO_CLIP, min(PRICE_RATIO_CLIP, math.log(current / other)))


def _extra_rows(lines: list[PricedLine]) -> list[list[float]]:
    cents = [round(priced.price * 100) for priced in lines]
    absolute = [abs(c) for c in cents]
    count = len(lines)
    sorted_desc = sorted(absolute, reverse=True)
    fuzzy_total = [
        fuzzy_lexicon_similarity(priced.line.text, TOTAL_WORDS) for priced in lines
    ]
    block = [block_sum_matches(cents, index) for index in range(count)]
    rows = []
    for index, priced in enumerate(lines):
        text = priced.line.text
        prev_index = index - 1 if index > 0 else None
        next_index = index + 1 if index + 1 < count else None
        rows.append(
            [
                1.0 if block[index] else 0.0,
                1.0 if discount_summary(cents, index) else 0.0,
                1.0
                if prev_index is not None and cents[prev_index] == cents[index]
                else 0.0,
                min(sum(1 for c in absolute if c == absolute[index]) - 1, 3) / 3.0,
                1.0 if tax_shaped(cents[index], cents) else 0.0,
                sorted_desc.index(absolute[index]) / max(count - 1, 1),
                index / max(count - 1, 1),
                *[
                    fuzzy_lexicon_similarity(text, lexicon)
                    for lexicon in FUZZY_LEXICONS.values()
                ],
                fuzzy_total[prev_index] if prev_index is not None else 0.0,
                fuzzy_total[next_index] if next_index is not None else 0.0,
                _log_ratio(
                    absolute[index],
                    absolute[prev_index] if prev_index is not None else None,
                ),
                _log_ratio(
                    absolute[index],
                    absolute[next_index] if next_index is not None else None,
                ),
                1.0 if prev_index is not None and block[prev_index] else 0.0,
                1.0 if next_index is not None and block[next_index] else 0.0,
                *hashed_trigrams(priced.label, HASH_BUCKETS),
            ]
        )
    return rows


def featurize(merged: list[PhysicalLine]) -> tuple[list[PricedLine], list[list[float]]]:
    lines, rows = featurize_v2(merged)
    if not lines:
        return [], []
    extras = _extra_rows(lines)
    return lines, [row + extra for row, extra in zip(rows, extras)]
