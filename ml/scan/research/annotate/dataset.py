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

import hashlib
from dataclasses import dataclass
from pathlib import Path

from annotate import record
from annotate.schema import ROLES
from annotate.validate import Cause, rejection
from paths import ANNOTATIONS_DIR
from reference.lines import PhysicalLine

HELD_OUT_CORPORA = ("photos_pixel", "T1-test")

# Une part d'`open_prices` réservée à l'évaluation. Sans elle, le seul terrain
# réaliste du jeu d'évaluation tenait en 20 photos, et le reste était des
# scans à plat d'une enseigne de 2017 : rien ne mesurait ce que l'app voit.
#
# Le tirage est **par ticket**, pas par enseigne. La production n'est pas
# « une enseigne jamais vue » — les dix premières enseignes font la moitié du
# corpus et c'est aussi là que les gens font leurs courses. Un tirage
# aléatoire reproduit cette distribution ; un tirage par enseigne mesurerait
# une tâche plus dure que la réalité.
#
# Le tirage est **déterministe** : dérivé du nom du ticket, il ne bouge pas
# entre deux exécutions et ne dépend d'aucun fichier d'état.
SLICED_CORPUS = "open_prices"

# Un quart, pas un dixième. À 10 % la tranche faisait 239 tickets jugeables et
# le bench avait un plancher de bruit de ±2 tickets : cinq tentatives
# successives sur le découpage du libellé ont toutes rendu entre −1 et +1, donc
# rien de mesurable. Un gain réel de trois tickets y était indistinguable du
# hasard d'un ordre d'échantillons.
#
# Le seuil portant sur un hachage, élargir est un **sur-ensemble** : aucun
# ticket ne change de côté, la tranche d'hier reste dedans. Ce que ça coûte est
# de l'entraînement — mesuré ci-dessous — et ce que ça achète est la capacité
# de juger, sans laquelle on construit à l'aveugle.
HELD_OUT_SHARE = 0.25

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
    names: list[str | None]
    quantities: list[float | None]
    sizes: list[str | None]
    store: str | None
    date: str | None

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
        names=[entry.get("name") for entry in stored.entries],
        quantities=[entry.get("quantity") for entry in stored.entries],
        sizes=[entry.get("size") for entry in stored.entries],
        store=stored.store,
        date=stored.date,
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
        whole_corpus_held_out = corpus_dir.name in HELD_OUT_CORPORA
        sliced = corpus_dir.name == SLICED_CORPUS
        if not sliced and whole_corpus_held_out != held_out:
            continue
        for path in sorted(corpus_dir.glob("*.json")):
            if sliced and is_held_out(path.stem) != held_out:
                continue
            stored = record.read(path)
            if _usable(stored, roles_only and not held_out):
                receipts.append(_receipt_of(stored, corpus_dir.name))
    return receipts


def is_held_out(name: str) -> bool:
    """Ce ticket appartient-il à la tranche d'évaluation ?

    Le verdict se calcule du nom seul : aucune liste à tenir à jour, aucun
    fichier d'état à désynchroniser, et un ticket ne peut pas changer de côté
    parce que le corpus a grossi."""
    digest = hashlib.sha256(name.encode()).digest()
    return int.from_bytes(digest[:4], "big") / 2**32 < HELD_OUT_SHARE


def role_counts(receipts: list[AnnotatedReceipt]) -> dict[str, int]:
    counts = dict.fromkeys(ROLES, 0)
    for receipt in receipts:
        for role in receipt.roles:
            counts[role] = counts.get(role, 0) + 1
    return counts
