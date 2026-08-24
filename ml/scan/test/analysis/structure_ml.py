"""Structuration V2 par classifieur de lignes — second avis gated checksum.

Le modèle n'étiquette que les lignes porteuses de prix (article / remise /
total / paiement / ignorer) ; les montants sont recopiés de l'OCR, les noms
suivent la même mécanique de libellé que les règles. Toute sortie repasse
par le checksum : le classifieur ne peut que sauver des tickets flagués,
jamais en corrompre un validé.
"""

from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

from line_features import featurize
from lines import PhysicalLine
from structure import (
    ExtractedItem,
    ExtractedReceipt,
    _clean_name,
    _find_date,
    _plausible_label,
    _rightmost_price,
)

MODEL_PATH = Path(__file__).parent / "models" / "line_clf.joblib"

ITEM, DISCOUNT, TOTAL, PAYMENT, IGNORE = 0, 1, 2, 3, 4

_model = None


def _load_model():
    global _model
    if _model is None:
        _model = joblib.load(MODEL_PATH)
    return _model


def extract_ml(merged: list[PhysicalLine]) -> ExtractedReceipt | None:
    lines, rows = featurize(merged)
    if not lines:
        return None
    predictions = _load_model().predict(np.array(rows))

    priced_indexes = {priced.index for priced in lines}
    pending_by_index: dict[int, str | None] = {}
    pending: str | None = None
    for index, line in enumerate(merged):
        pending_by_index[index] = pending
        if index in priced_indexes:
            pending = None
        else:
            pending = _plausible_label(line.text)

    items: list[ExtractedItem] = []
    total: float | None = None
    payment: float | None = None
    for priced, prediction in zip(lines, predictions):
        price = round(priced.price, 2)
        if prediction == ITEM:
            label = _plausible_label(priced.label)
            name = label or pending_by_index[priced.index] or priced.label
            items.append(
                ExtractedItem(
                    name=_clean_name(name), amount=price, discount=0.0
                )
            )
        elif prediction == DISCOUNT and items:
            items[-1].discount = round(items[-1].discount + abs(price), 2)
        elif prediction == TOTAL:
            total = price
        elif prediction == PAYMENT and payment is None:
            payment = price

    if not items:
        return None
    return ExtractedReceipt(
        store=merged[0].text if merged else None,
        date=_find_date(merged),
        total=total,
        subtotal=None,
        payment=payment,
        items=items,
    )
