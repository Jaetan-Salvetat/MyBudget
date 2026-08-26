"""Les lectures concurrentes d'un même ticket, pour arbitrer un golden bancal.

Deux chaînes indépendantes de l'annotation golden :

- la **transcription officielle FindIt** — du texte parfait, ligne par ligne,
  passé par la même structuration que les images ;
- le **corpus annoté** — le ticket relu depuis l'image, ligne par ligne, avec
  le rôle de chacune et le libellé rattaché à son prix.

Aucune n'est réputée juste : `truth.golden` ne retient que celle qui boucle.
"""

from __future__ import annotations

import json
from pathlib import Path

from annotate.schema import DISCOUNT, ITEM, ITEM_LABEL, TOTAL
from paths import DATA_DIR, FINDIT_DIR
from reference.lines import PhysicalLine, Word
from reference.structure import _clean_name, _label_of, _rightmost_price
from truth.transcript import extract_from_transcript

ANNOTATIONS_ROOT = DATA_DIR / "annotations"


def _physical(line: dict) -> PhysicalLine:
    return PhysicalLine(
        words=[
            Word(
                text=word["text"],
                left=word["box"][0],
                top=word["box"][1],
                right=word["box"][2],
                bottom=word["box"][3],
                confidence=word.get("confidence"),
            )
            for word in line["words"]
        ]
    )


def _label_of_line(line: dict) -> str:
    """Le texte de la ligne débarrassé de son prix — ce qui nomme."""
    physical = _physical(line)
    priced = _rightmost_price(physical)
    return _clean_name(_label_of(physical, priced[1]) if priced else physical.text)


def receipt_from_annotation(record: dict) -> dict | None:
    """Le reçu que décrit une annotation de lignes, libellés rattachés."""
    annotation = record.get("annotation")
    if not annotation:
        return None
    lines = record["lines"]
    items: list[dict] = []
    total: float | None = None
    pending: str | None = None
    for row in annotation["lines"]:
        role, amount = row["role"], row.get("amount")
        if role == ITEM_LABEL:
            pending = _label_of_line(lines[row["index"]])
            continue
        if role == ITEM:
            if amount is not None:
                target = row.get("label_index")
                named = (
                    _label_of_line(lines[target])
                    if target is not None and 0 <= target < len(lines)
                    else pending or _label_of_line(lines[row["index"]])
                )
                items.append(
                    {
                        "name": named,
                        "amount": float(amount),
                        "discount": float(row.get("discount") or 0.0),
                    }
                )
            pending = None
            continue
        if role == DISCOUNT and items and amount is not None:
            items[-1]["discount"] = round(items[-1]["discount"] + abs(float(amount)), 2)
            continue
        if role == TOTAL and amount is not None:
            total = float(amount)
        pending = None
    return {
        "store": annotation.get("store"),
        "date": annotation.get("date"),
        "total": total,
        "items": items,
    }


def annotated_receipt(split: str, document: str) -> dict | None:
    path = ANNOTATIONS_ROOT / split / f"{document}.json"
    if not path.exists():
        return None
    return receipt_from_annotation(json.loads(path.read_text()))


def transcript_receipt(split: str, document: str) -> dict | None:
    path = FINDIT_DIR / split / "txt" / f"{document}.txt"
    if not path.exists():
        return None
    extracted = extract_from_transcript(path)
    return {
        "store": extracted.store,
        "date": extracted.date,
        "total": extracted.total,
        "items": [
            {"name": item.name, "amount": item.amount, "discount": item.discount}
            for item in extracted.items
        ],
    }


def alternatives(split: str, document: str) -> list[dict | None]:
    """Les lectures concurrentes, dans l'ordre où elles font foi : la
    transcription d'abord — elle ne dépend d'aucun OCR."""
    return [
        transcript_receipt(split, document),
        annotated_receipt(split, document),
    ]
