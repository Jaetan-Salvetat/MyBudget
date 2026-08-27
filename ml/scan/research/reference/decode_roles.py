"""Décodage sous contrainte guidé par le tagger de rôles.

Le décodeur cherche l'étiquetage le plus probable dont Σ(articles − remises)
tombe au centime sur une référence imprimée. Il consommait jusqu'ici les
probabilités du classifieur V2 : cinq classes, lignes porteuses de prix
seules, supervisé par les règles sur une seule enseigne.

Le tagger répond à la même question sur un corpus qui n'a plus rien à voir —
toutes les lignes, 2 827 tickets annotés depuis l'image, 337 enseignes — et
ses neuf rôles se projettent sur les cinq classes du décodeur. C'est la seule
chose qui change : mêmes invariants, même somme exacte, mêmes montants
recopiés de l'OCR.
"""

from __future__ import annotations

import numpy as np

from annotate.schema import DISCOUNT as ROLE_DISCOUNT
from annotate.schema import ITEM as ROLE_ITEM
from annotate.schema import PAYMENT as ROLE_PAYMENT
from annotate.schema import SUBTOTAL as ROLE_SUBTOTAL
from annotate.schema import TOTAL as ROLE_TOTAL
from reference.decode_constrained import (
    _rank_alternatives,
    _with_chosen_amounts,
    decode,
)
from reference.decoded_receipt import receipt_from_labels, single_item_receipt
from reference.header_ml import role_probabilities
from reference.line_features import PricedLine, priced_lines
from reference.line_labels import DISCOUNT, IGNORE, ITEM, PAYMENT, TAGGER_ROLES, TOTAL
from reference.lines import PhysicalLine
from reference.structure import ExtractedReceipt, _printed_count

# Un rôle non listé ne contribue à rien : il tombe dans `IGNORE`, la classe
# fourre-tout du décodeur. `subtotal` rejoint `total` — les deux sont des
# références de checksum, et le décodeur les départage par sa propre
# éligibilité de rang, pas par leur nom.
ROLE_TO_DECODER_CLASS = {
    ROLE_ITEM: ITEM,
    ROLE_DISCOUNT: DISCOUNT,
    ROLE_TOTAL: TOTAL,
    ROLE_SUBTOTAL: TOTAL,
    ROLE_PAYMENT: PAYMENT,
}

DECODER_CLASSES = 5


def decoder_probabilities(
    role_probas: np.ndarray, priced: list[PricedLine]
) -> np.ndarray:
    """Les probabilités du tagger, restreintes aux lignes chiffrées et
    repliées sur les cinq classes du décodeur. Replier, c'est sommer : la
    probabilité qu'une ligne soit une référence est celle qu'elle soit un
    total *ou* un sous-total."""
    folded = np.zeros((len(priced), DECODER_CLASSES))
    for row, line in enumerate(priced):
        if line.index >= len(role_probas):
            folded[row, IGNORE] = 1.0
            continue
        for column, role in enumerate(TAGGER_ROLES):
            folded[row, ROLE_TO_DECODER_CLASS.get(role, IGNORE)] += role_probas[
                line.index, column
            ]
    return folded


def extract_role_constrained(
    merged: list[PhysicalLine],
    lines: list[PhysicalLine] | None = None,
    alternatives: dict[int, int] | None = None,
    role_probas: np.ndarray | None = None,
    **decode_params,
) -> ExtractedReceipt | None:
    """`merged` porte les prix recollés, `lines` ce que le tagger a appris à
    lire — les deux ont le même nombre de lignes, le rang les aligne. Passer
    `role_probas` évite de réinférer quand l'appelant les a déjà."""
    priced = priced_lines(merged)
    if not priced:
        return None
    if role_probas is None:
        role_probas = role_probabilities(lines if lines is not None else merged)
    probas = decoder_probabilities(role_probas, priced)
    hypothesis = decode(
        priced,
        probas,
        printed_count=_printed_count(merged),
        alternatives=_rank_alternatives(priced, alternatives),
        **decode_params,
    )
    if hypothesis is None:
        return None
    reference_total = hypothesis.reference_cents / 100
    if hypothesis.single_item:
        return single_item_receipt(merged, reference_total)
    chosen = (
        _with_chosen_amounts(priced, hypothesis.labels, hypothesis.cents)
        if hypothesis.cents
        else priced
    )
    return receipt_from_labels(
        merged, chosen, hypothesis.labels, reference_total=reference_total
    )
