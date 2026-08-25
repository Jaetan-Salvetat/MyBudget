"""Structuration par classifieur de lignes — second avis gated checksum.

Le modèle n'étiquette que les lignes porteuses de prix (article / remise /
total / paiement / ignorer) ; les montants sont recopiés de l'OCR, les noms
suivent la même mécanique de libellé que les règles. Toute sortie repasse
par le checksum : le classifieur ne peut que sauver des tickets flagués,
jamais en corrompre un validé. Deux artefacts : V2 (32 features) et V3
(features arithmétiques + lexiques flous + trigrammes, actif), chacun lié à
son featurizer.
"""

from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

from invariants import Constraints, constraints
from line_features import PricedLine
from line_features import featurize as featurize_v2
from line_features_v3 import featurize as featurize_v3
from lines import PhysicalLine
from structure import (
    ExtractedItem,
    ExtractedReceipt,
    _clean_name,
    _find_date,
    _plausible_label,
)

MODELS_DIR = Path(__file__).parent / "models"
MODEL_PATHS = {
    "v2": MODELS_DIR / "line_clf.joblib",
    "v3": MODELS_DIR / "line_clf_v3.joblib",
}
FEATURIZERS = {"v2": featurize_v2, "v3": featurize_v3}
ACTIVE_VERSION = "v3"

ITEM, DISCOUNT, TOTAL, PAYMENT, IGNORE = 0, 1, 2, 3, 4

_models: dict[str, object] = {}


def load_classifier(version: str | None = None):
    """(modèle, featurizer) de la version active — les deux doivent toujours
    venir du même artefact."""
    version = version or ACTIVE_VERSION
    if version not in _models:
        _models[version] = joblib.load(MODEL_PATHS[version])
    return _models[version], FEATURIZERS[version]


def _pending_labels(
    merged: list[PhysicalLine], lines: list[PricedLine]
) -> dict[int, str | None]:
    priced_indexes = {priced.index for priced in lines}
    pending_by_index: dict[int, str | None] = {}
    pending: str | None = None
    for index, line in enumerate(merged):
        pending_by_index[index] = pending
        pending = None if index in priced_indexes else _plausible_label(line.text)
    return pending_by_index


def receipt_from_labels(
    merged: list[PhysicalLine],
    lines: list[PricedLine],
    labels: list[int],
    reference_total: float | None = None,
) -> ExtractedReceipt | None:
    """Reçu structuré depuis les rôles par ligne. Un prix négatif est
    toujours une remise, quel que soit son label : un article ne peut pas
    être négatif. `reference_total` : montant de référence prouvé sans ligne
    total étiquetée (décomposition TVA, espèces − rendu)."""
    pending_by_index = _pending_labels(merged, lines)
    items: list[ExtractedItem] = []
    total: float | None = None
    payment: float | None = None
    for priced, label in zip(lines, labels):
        price = round(priced.price, 2)
        if label == ITEM and price < 0:
            label = DISCOUNT
        if label == ITEM:
            name = (
                _plausible_label(priced.label)
                or pending_by_index[priced.index]
                or priced.label
            )
            items.append(
                ExtractedItem(name=_clean_name(name), amount=price, discount=0.0)
            )
        elif label == DISCOUNT and items:
            items[-1].discount = round(items[-1].discount + abs(price), 2)
        elif label == TOTAL:
            total = price
        elif label == PAYMENT and payment is None:
            payment = price
    if not items:
        return None
    return ExtractedReceipt(
        store=_store_of(merged),
        date=_find_date(merged),
        total=total if total is not None else reference_total,
        subtotal=None,
        payment=payment,
        items=items,
    )


def _store_of(merged: list[PhysicalLine]) -> str | None:
    return merged[0].text if merged else None


def single_item_receipt(merged: list[PhysicalLine], total: float) -> ExtractedReceipt:
    """Ticket sans ligne d'article : l'unique achat porte le montant prouvé
    et le nom de l'enseigne."""
    store = _store_of(merged)
    return ExtractedReceipt(
        store=store,
        date=_find_date(merged),
        total=total,
        subtotal=None,
        payment=None,
        items=[
            ExtractedItem(name=_clean_name(store or ""), amount=total, discount=0.0)
        ],
    )


def constrained_labels(labels: list[int], structure: Constraints) -> list[int]:
    """Applique les invariants structurels à un étiquetage argmax : une ligne
    exclue est ignorée, un total hors des rangs éligibles aussi."""
    return [
        IGNORE
        if rank in structure.forced_ignore
        or (label == TOTAL and rank not in structure.reference_ranks)
        or (label == ITEM and rank in structure.soft_ignore)
        else label
        for rank, label in enumerate(labels)
    ]


def extract_ml(merged: list[PhysicalLine]) -> ExtractedReceipt | None:
    model, featurize = load_classifier()
    lines, rows = featurize(merged)
    if not lines:
        return None
    predictions = [int(p) for p in model.predict(np.array(rows))]
    labels = constrained_labels(predictions, constraints(lines))
    return receipt_from_labels(merged, lines, labels)
