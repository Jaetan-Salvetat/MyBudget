"""Structuration décidée par le tagger de rôles.

Les règles déduisent de la géométrie et de lexiques quelles lignes sont des
articles ; le tagger, lui, apprend la question sur toutes les lignes du
corpus, et il y répond mieux — F1 0,987 sur les 2 195 lignes d'article du
held-out. Il ne servait pourtant qu'à désigner l'enseigne et la date : la
décision « article ou pas » ne lui était jamais demandée.

Elle l'est ici. Les montants restent recopiés de l'OCR, jamais recalculés ;
les libellés suivent la même colonne que les règles ; et le checksum reste
juge. Comme le classifieur de lignes, cet étage ne peut que sauver un ticket
flagué, jamais en corrompre un vérifié.

Miroir de `pipeline/lib/src/structure_roles.dart`.
"""

from __future__ import annotations

from annotate.schema import DISCOUNT, ITEM, ITEM_LABEL, PAYMENT, SUBTOTAL, TOTAL
from reference.lines import PhysicalLine
from reference.structure import (
    ExtractedItem,
    ExtractedReceipt,
    _clean_name,
    _find_date,
    _label_column_left,
    _label_zone,
    _plausible_label,
    _rightmost_price,
)


def extract_roles(
    merged: list[PhysicalLine], roles: list[str]
) -> ExtractedReceipt | None:
    """Le reçu que décrivent ces rôles. `merged` et `roles` sont alignés."""
    column = _label_column_left(merged)
    items: list[ExtractedItem] = []
    total: float | None = None
    subtotal: float | None = None
    payment: float | None = None
    pending: str | None = None

    for index, line in enumerate(merged):
        role = roles[index] if index < len(roles) else None
        if role == ITEM_LABEL:
            pending = _plausible_label(line.text)
            continue

        priced = _rightmost_price(line)
        if priced is None:
            continue
        price = round(priced[0], 2)

        # Un article ne peut pas être négatif : quel que soit le rôle prédit,
        # un montant négatif se déduit du précédent.
        if role == ITEM and price >= 0:
            # Un `item_label` désigné prime sur la zone de gauche : le tagger
            # a dit que le nom était ailleurs, et une pesée lisible
            # (« 0,792 kg 2,65 EUR/kg ») ne doit pas le contredire au seul
            # motif qu'elle porte des lettres.
            zone = _label_zone(line, column).strip()
            items.append(
                ExtractedItem(
                    name=_clean_name(pending or _plausible_label(zone) or zone),
                    amount=price,
                    discount=0.0,
                    line_index=index,
                )
            )
            pending = None
        elif (role == DISCOUNT or (role == ITEM and price < 0)) and items:
            items[-1].discount = round(items[-1].discount + abs(price), 2)
        elif role == TOTAL and total is None:
            total = price
        elif role == SUBTOTAL and subtotal is None:
            subtotal = price
        elif role == PAYMENT and payment is None:
            payment = price

    if not items:
        return None
    return ExtractedReceipt(
        store=merged[0].text if merged else None,
        date=_find_date(merged),
        total=total,
        subtotal=subtotal,
        payment=payment,
        items=items,
    )
