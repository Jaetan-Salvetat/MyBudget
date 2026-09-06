"""Le flow local : une lecture du ticket, un étiqueteur, une somme prouvée.

Il n'y a plus d'étages. La version précédente en enchaînait six — règles,
argmax du classifieur V2, décodage sous contrainte, tagger de rôles, sur la
passe 1 puis le retry puis leur fusion — chacun rattrapant ce que le
précédent ratait, le checksum arbitrant. Mesuré sur 483 tickets à vérité
golden (`bench/flows.py`), cet empilement rend **exactement le même nombre de
tickets justes** qu'un seul étiqueteur suivi d'un seul décodeur : 341 contre
341. Ce qu'il ajoutait, c'étaient sept tickets badgés « vérifié » de plus —
et quatre tickets à montant faux de plus avec eux. Il fabriquait de la
confiance, pas de la justesse.

Ce qui reste :

    lecture (passe 1 → retry → fusion, la suivante seulement si besoin)
      → le tagger de rôles étiquette toutes les lignes
      → le décodeur retient l'étiquetage le plus probable dont
        Σ(articles − remises) tombe au centime sur une référence imprimée
      → vérifié, ou écran de confirmation

Le tagger est le seul modèle de lignes : il voit tout le ticket, il sort de
2 827 tickets annotés depuis l'image sur 337 enseignes, et le classifieur V2
qu'il remplace ne savait rien qu'il ne sache — même nombre de tickets justes,
trois tickets à montant faux en moins.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from reference.decode_roles import extract_role_constrained
from reference.fuse_passes import fuse_passes
from reference.header_ml import predicted_roles, role_probabilities
from reference.lines import PhysicalLine, Word, cluster_lines, deskew_words
from reference.structure import ExtractedItem, merge_price_fragments
from reference.structure_roles import extract_roles

PASS1 = "passe1"
RETRY = "retry"
FUSED = "fusion"
CONFIRM = "confirm"

VERIFIED_SOURCES = (PASS1, RETRY, FUSED)


class Source:
    """Une lecture du ticket : les lignes telles que les modèles les ont
    apprises, les mêmes avec les prix recollés, et — pour la fusion — les
    montants que l'autre passe lit autrement.

    Le tagger et le décodeur travaillent sur des lignes différentes et le rang
    les aligne : `merge_price_fragments` recolle des mots *dans* une ligne,
    jamais deux lignes entre elles."""

    def __init__(
        self,
        name: str,
        lines: list[PhysicalLine],
        alternatives: dict[int, int] | None = None,
    ) -> None:
        self.name = name
        self.lines = lines
        self.merged = [merge_price_fragments(line) for line in lines]
        self.alternatives = alternatives
        self._roles: np.ndarray | None = None

    @property
    def roles(self) -> np.ndarray:
        """Les probabilités de rôle, inférées une fois par lecture."""
        if self._roles is None:
            self._roles = role_probabilities(self.lines)
        return self._roles


@dataclass(frozen=True)
class LocalOutcome:
    """Ce que le flow a lu, et par quelle lecture.

    `source` remplace l'ancien `stage` : il ne dit plus quel étage a sauvé le
    ticket — il n'y en a qu'un — mais quelle lecture de l'image a porté la
    somme prouvée. `CONFIRM` dit que rien ne l'a prouvée."""

    source: str
    items: list[ExtractedItem]
    total: float | None
    lines: list[PhysicalLine]

    @property
    def verified(self) -> bool:
        return self.source in VERIFIED_SOURCES

    @property
    def stage(self) -> str:
        """Compatibilité des benchs historiques, qui comptent des étages."""
        return self.source

    @property
    def amounts(self) -> list[tuple[float, float]]:
        return [(round(i.amount, 2), round(i.discount, 2)) for i in self.items]


def clustered_lines(dump: dict) -> list[PhysicalLine]:
    words = []
    angles = []
    for block in dump["blocks"]:
        for line in block["lines"]:
            if line.get("angle") is not None:
                angles.append(line["angle"])
            for element in line["elements"]:
                left, top, right, bottom = element["box"]
                words.append(
                    Word(
                        text=element["text"],
                        left=left,
                        top=top,
                        right=right,
                        bottom=bottom,
                        confidence=element.get("confidence"),
                    )
                )
    angle = sorted(angles)[len(angles) // 2] if angles else 0.0
    return cluster_lines(deskew_words(words, angle))


def sources(dump: dict):
    """Les lectures, de la moins chère à la plus chère. Générateur : le second
    OCR ne coûte que sur les tickets que la passe 1 ne prouve pas."""
    first = Source(PASS1, clustered_lines(dump))
    yield first
    if "ocrRetry" not in dump:
        return
    second = clustered_lines(dump["ocrRetry"])
    yield Source(RETRY, second)
    fused = fuse_passes(first.lines, second)
    yield Source(FUSED, fused.lines, fused.alternatives)


def read(source: Source):
    """Le reçu que cette lecture prouve, ou rien."""
    receipt = extract_role_constrained(
        source.merged, alternatives=source.alternatives, role_probas=source.roles
    )
    return receipt if receipt is not None and receipt.checksum_ok else None


def _unverified(source: Source) -> LocalOutcome:
    """Ce qu'on affiche quand aucune somme n'est prouvée : l'argmax du tagger,
    tel quel. Il pré-remplit l'écran de confirmation — et n'est jamais badgé
    vérifié."""
    receipt = extract_roles(source.merged, predicted_roles(source.lines))
    return LocalOutcome(
        CONFIRM,
        receipt.items if receipt is not None else [],
        receipt.total if receipt is not None else None,
        source.lines,
    )


def decide_local(dump: dict) -> LocalOutcome:
    last = None
    for source in sources(dump):
        last = source
        receipt = read(source)
        if receipt is not None:
            return LocalOutcome(
                source.name, receipt.items, receipt.verified_total, source.lines
            )
    return (
        _unverified(last) if last is not None else LocalOutcome(CONFIRM, [], None, [])
    )
