"""Les lignes porteuses d'un prix — ce sur quoi le décodeur raisonne.

Un ticket se lit à deux granularités : toutes ses lignes, que le tagger de
rôles étiquette, et les seules lignes qui portent un montant, que le décodeur
combine pour retomber sur le total. `PricedLine` est cette seconde vue, et
`index` est ce qui la rattache à la première.

Une ligne y entre avec **tous** ses montants plausibles, pas un seul. La
lecture principale reste la lecture stricte ; les autres sont là pour que le
décodeur puisse en préférer une quand c'est elle qui fait retomber la somme.
Quelles lignes ont droit à cette largeur est décidé par le tagger, pas ici :
`lax_ranks` porte sa réponse.

Ce module portait aussi le featuriseur du classifieur de lignes V2. Ce
classifieur est mort — mesuré sans effet sur le nombre de tickets justes, et
le tagger fait mieux ce qu'il faisait.
"""

from __future__ import annotations

from collections.abc import Container

from reference.lines import PhysicalLine
from reference.structure import merge_price_fragments, price_candidates


class PricedLine:
    """Une ligne fusionnée porteuse d'un prix, et sa place dans le ticket.

    `price` est la lecture principale ; `candidates` les montants que la ligne
    peut porter, celle-ci en tête."""

    def __init__(
        self,
        index: int,
        line: PhysicalLine,
        price: float,
        word,
        candidates: list[float] | None = None,
    ):
        self.index = index
        self.line = line
        self.price = price
        self.word = word
        self.candidates = [price] if candidates is None else candidates

    @property
    def label(self) -> str:
        return " ".join(w.text for w in self.line.words if w is not self.word).strip()


def priced_lines(
    merged: list[PhysicalLine], lax_ranks: Container[int] = frozenset()
) -> list[PricedLine]:
    result = []
    for index, line in enumerate(merged):
        candidates = price_candidates(line, lax=index in lax_ranks)
        if not candidates:
            continue
        price, word = candidates[0]
        result.append(PricedLine(index, line, price, word, [c for c, _ in candidates]))
    return result


def merged_lines(raw_lines: list[PhysicalLine]) -> list[PhysicalLine]:
    return [merge_price_fragments(line) for line in raw_lines]
