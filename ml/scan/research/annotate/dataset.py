"""Le corpus d'entraînement : lignes de ticket et leur rôle.

Format neutre, indépendant de l'architecture du modèle — chaque ticket est
une séquence de lignes physiques (texte + géométrie) et la séquence de rôles
correspondante. Seules les annotations qui ont franchi le filtre entrent.

Séparation figée : les photos prises au téléphone et le split FindIt T1-test
sont réservés à l'évaluation. Ils ne servent jamais à entraîner — le premier
parce qu'il est le seul terrain réaliste, le second parce qu'il porte une
vérité indépendante.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from annotate.run import ANNOTATIONS_DIR
from annotate.schema import ROLES
from reference.lines import PhysicalLine, Word

HELD_OUT_CORPORA = ("photos_pixel", "T1-test")

# Un ticket rejeté parce qu'un montant annoté est illisible sur sa ligne —
# l'OCR a soudé un code au prix — garde des *rôles* plausibles : le checksum
# protège les montants, pas l'étiquetage des lignes. Ces tickets sont donc
# utilisables pour entraîner le tagger de rôles, et seulement pour lui : rien
# de ce qui touche aux montants ne doit s'y fier.
UNREADABLE_AMOUNT_REASON = "illisible"


@dataclass(frozen=True)
class AnnotatedReceipt:
    name: str
    corpus: str
    lines: list[PhysicalLine]
    roles: list[str]
    amounts: list[float | None]
    discounts: list[float | None]
    label_indexes: list[int | None]

    def __post_init__(self) -> None:
        if not len(self.lines) == len(self.roles) == len(self.amounts):
            raise ValueError(f"{self.name} : séquences de longueurs différentes")


def _line_of(line: dict) -> PhysicalLine:
    return PhysicalLine(
        words=[
            Word(
                text=word["text"],
                left=word["box"][0],
                top=word["box"][1],
                right=word["box"][2],
                bottom=word["box"][3],
                confidence=word["confidence"],
            )
            for word in line["words"]
        ]
    )


def _receipt_of(record: dict, corpus: str) -> AnnotatedReceipt:
    entries = sorted(record["annotation"]["lines"], key=lambda entry: entry["index"])
    return AnnotatedReceipt(
        name=record["image"],
        corpus=corpus,
        lines=[_line_of(line) for line in record["lines"]],
        roles=[entry["role"] for entry in entries],
        amounts=[entry.get("amount") for entry in entries],
        discounts=[entry.get("discount") for entry in entries],
        label_indexes=[entry.get("label_index") for entry in entries],
    )


def _usable(record: dict, roles_only: bool) -> bool:
    if "annotation" not in record or "lines" not in record:
        return False
    reason = record.get("reason")
    if reason is None:
        return True
    return roles_only and UNREADABLE_AMOUNT_REASON in reason


def load(
    held_out: bool = False,
    root: Path = ANNOTATIONS_DIR,
    roles_only: bool = False,
) -> list[AnnotatedReceipt]:
    """Les tickets annotés et acceptés. `held_out` sélectionne le jeu
    d'évaluation au lieu du jeu d'entraînement.

    `roles_only` ajoute les tickets écartés pour un montant illisible : leurs
    rôles restent exploitables. Réservé à l'entraînement du tagger — le jeu
    d'évaluation, lui, reste strict."""
    receipts = []
    for corpus_dir in sorted(root.iterdir()):
        if not corpus_dir.is_dir():
            continue
        if (corpus_dir.name in HELD_OUT_CORPORA) != held_out:
            continue
        for path in sorted(corpus_dir.glob("*.json")):
            record = json.loads(path.read_text())
            if not _usable(record, roles_only and not held_out):
                continue
            receipts.append(_receipt_of(record, corpus_dir.name))
    return receipts


def role_counts(receipts: list[AnnotatedReceipt]) -> dict[str, int]:
    counts = dict.fromkeys(ROLES, 0)
    for receipt in receipts:
        for role in receipt.roles:
            counts[role] = counts.get(role, 0) + 1
    return counts
