"""Les signaux qu'une ligne de ticket porte, sans modèle ni featuriseur.

Ils décrivent des faits arithmétiques ou typographiques : ce prix est-il la
somme d'un bloc au-dessus ? une fraction de TVA d'un autre ? ce libellé
ressemble-t-il à un mot du lexique malgré l'OCR (`Tota1`, `TOT AL`, `LU.A`) ?
Les featuriseurs — lignes, mots — s'en servent, la vérité de rôle aussi.

Ils vivaient dans `line_features_v3`, à côté du featuriseur du classifieur
V2/V3. Ce classifieur est mort — le tagger de rôles fait mieux ce qu'il
faisait — mais les signaux, eux, sont indépendants du modèle qui les lit.
"""

from __future__ import annotations

import math
import re
import unicodedata
import zlib

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
