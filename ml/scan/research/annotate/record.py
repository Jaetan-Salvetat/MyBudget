"""Le format d'un ticket annoté sur disque — seul module qui l'écrit et le lit.

Un fichier par ticket : les lignes physiques telles que le pipeline les a
reconstruites, le rôle de chacune, et la provenance de l'annotation.

Ce qui **n'est pas** stocké, parce qu'il se déduit :

- le texte d'une ligne — c'est la jointure de ses mots ;
- l'index d'une entrée — c'est son rang, le filtre garantit la bijection ;
- le verdict du filtre — il se recalcule au chargement, en 0,15 s pour tout
  le corpus, et le stocker le laisserait mentir dès que le filtre bouge.

La provenance, elle, ne se déduit d'aucune source : elle dit quel modèle et
quelle version du prompt ont produit l'annotation. C'est ce qui permet de
ré-annoter le périmé sans repayer le corpus entier.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from reference.lines import PhysicalLine, Word

COORDINATE_DECIMALS = 2
# La confiance vient d'un OCR qui la rend en float32 : au-delà de deux
# décimales, on stockerait du bruit de conversion (« 0.30000001192092896 »).
CONFIDENCE_DECIMALS = 2
# La date d'annotation trace, elle ne périme rien : seuls le modèle et le
# prompt décident de ce que vaut une annotation.
IDENTITY_KEYS = ("model", "prompt")


@dataclass(frozen=True)
class Record:
    image: str
    lines: list[PhysicalLine]
    entries: list[dict]
    store: str | None
    date: str | None
    provenance: dict


def _word_of(word: dict) -> Word:
    left, top, right, bottom = word["box"]
    return Word(
        text=word["text"],
        left=left,
        top=top,
        right=right,
        bottom=bottom,
        confidence=word["confidence"],
    )


def _serialized(word: Word) -> dict:
    return {
        "text": word.text,
        "box": [
            round(value, COORDINATE_DECIMALS)
            for value in (word.left, word.top, word.right, word.bottom)
        ],
        "confidence": None
        if word.confidence is None
        else round(word.confidence, CONFIDENCE_DECIMALS),
    }


def lines_of(payload: dict) -> list[PhysicalLine]:
    """Les lignes physiques d'un fichier déjà lu."""
    return [
        PhysicalLine(words=[_word_of(word) for word in line["words"]])
        for line in payload["lines"]
    ]


def read(path: Path) -> Record:
    payload = json.loads(path.read_text())
    annotation = payload.get("annotation") or {}
    return Record(
        image=payload["image"],
        lines=lines_of(payload),
        entries=annotation.get("lines") or [],
        store=annotation.get("store"),
        date=annotation.get("date"),
        provenance=payload.get("provenance") or {},
    )


def write(
    path: Path,
    image: str,
    lines: list[PhysicalLine],
    entries: list[dict],
    store: str | None,
    date: str | None,
    provenance: dict,
) -> None:
    payload = {
        "image": image,
        "provenance": provenance,
        "lines": [
            {"words": [_serialized(word) for word in line.words]} for line in lines
        ],
        "annotation": {"lines": entries, "store": store, "date": date},
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False))


def is_stale(stored: Record, provenance: dict) -> bool:
    """Le ticket a-t-il été annoté par autre chose que ce qui tourne
    aujourd'hui ? Une provenance absente est périmée : on ne sait pas."""
    return any(
        stored.provenance.get(key) != provenance.get(key) for key in IDENTITY_KEYS
    )
