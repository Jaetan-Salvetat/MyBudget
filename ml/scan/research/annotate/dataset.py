"""Le corpus d'entraînement : lignes de ticket et leur rôle.

Format neutre, indépendant de l'architecture du modèle — chaque ticket est
une séquence de lignes physiques (texte + géométrie) et la séquence de rôles
correspondante.

Le filtre est rejoué ici, à chaque chargement : rien sur le disque ne dit
si un ticket entre ou non. Le recalcul coûte l'équivalent de la lecture des
fichiers, et il garantit que le corpus obéit toujours à la version courante
des règles — un verdict stocké, lui, mentirait dès qu'on y touche.

Séparation figée : les photos prises au téléphone et le split FindIt T1-test
sont réservés à l'évaluation. Ils ne servent jamais à entraîner — le premier
parce qu'il est le seul terrain réaliste, le second parce qu'il porte une
vérité indépendante.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from annotate import record
from annotate.schema import ROLES
from annotate.validate import Cause, rejection
from paths import ANNOTATIONS_DIR
from reference.lines import PhysicalLine

HELD_OUT_CORPORA = ("photos_pixel", "T1-test")

# Un ticket rejeté parce qu'un montant annoté est illisible sur sa ligne —
# l'OCR a soudé un code au prix — garde des *rôles* plausibles : le checksum
# protège les montants, pas l'étiquetage des lignes. Ces tickets sont donc
# utilisables pour entraîner le tagger de rôles, et seulement pour lui : rien
# de ce qui touche aux montants ne doit s'y fier.
ROLES_ONLY_CAUSE = Cause.UNREADABLE_AMOUNT


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


def _receipt_of(stored: record.Record, corpus: str) -> AnnotatedReceipt:
    return AnnotatedReceipt(
        name=stored.image,
        corpus=corpus,
        lines=stored.lines,
        roles=[entry["role"] for entry in stored.entries],
        amounts=[entry.get("amount") for entry in stored.entries],
        discounts=[entry.get("discount") for entry in stored.entries],
        label_indexes=[entry.get("label_index") for entry in stored.entries],
    )


def _usable(stored: record.Record, roles_only: bool) -> bool:
    if not stored.lines:
        return False
    verdict = rejection(stored.entries, stored.lines)
    if verdict is None:
        return True
    return roles_only and verdict.cause is ROLES_ONLY_CAUSE


def load(
    held_out: bool = False,
    root: Path = ANNOTATIONS_DIR,
    roles_only: bool = False,
) -> list[AnnotatedReceipt]:
    """Les tickets annotés que le filtre accepte. `held_out` sélectionne le
    jeu d'évaluation au lieu du jeu d'entraînement.

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
            stored = record.read(path)
            if _usable(stored, roles_only and not held_out):
                receipts.append(_receipt_of(stored, corpus_dir.name))
    return receipts


def role_counts(receipts: list[AnnotatedReceipt]) -> dict[str, int]:
    counts = dict.fromkeys(ROLES, 0)
    for receipt in receipts:
        for role in receipt.roles:
            counts[role] = counts.get(role, 0) + 1
    return counts
