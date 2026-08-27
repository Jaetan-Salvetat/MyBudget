"""Le reçu que décrit un étiquetage de lignes.

Le décodeur rend une étiquette par ligne chiffrée — article, remise,
référence, paiement, ignoré. Ce module en fait un reçu : les montants sont
**recopiés de l'OCR**, jamais recalculés, et un prix négatif est toujours une
remise quel que soit son étiquette, parce qu'un article ne peut pas l'être.

C'est tout ce qui reste de `structure_ml.py`, qui portait aussi le
classifieur de lignes V2 et sa structuration — mesurés sans effet sur le
nombre de tickets justes, supprimés.
"""

from __future__ import annotations

from reference.line_features import PricedLine
from reference.line_labels import DISCOUNT, ITEM, PAYMENT, TOTAL
from reference.lines import PhysicalLine
from reference.structure import (
    ExtractedItem,
    ExtractedReceipt,
    _clean_name,
    _find_date,
    _label_column_left,
    _label_zone,
    _plausible_label,
)


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
    label_column = _label_column_left(merged)
    items: list[ExtractedItem] = []
    total: float | None = None
    payment: float | None = None
    for priced, label in zip(lines, labels):
        price = round(priced.price, 2)
        if label == ITEM and price < 0:
            label = DISCOUNT
        if label == ITEM:
            zone = _label_zone(priced.line, label_column).strip()
            name = _plausible_label(zone) or pending_by_index[priced.index] or zone
            items.append(
                ExtractedItem(
                    name=_clean_name(name),
                    amount=price,
                    discount=0.0,
                    line_index=priced.index,
                )
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
