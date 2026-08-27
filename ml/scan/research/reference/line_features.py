"""Les lignes porteuses d'un prix — ce sur quoi le décodeur raisonne.

Un ticket se lit à deux granularités : toutes ses lignes, que le tagger de
rôles étiquette, et les seules lignes qui portent un montant, que le décodeur
combine pour retomber sur le total. `PricedLine` est cette seconde vue, et
`index` est ce qui la rattache à la première.

Ce module portait aussi le featuriseur du classifieur de lignes V2. Ce
classifieur est mort — mesuré sans effet sur le nombre de tickets justes, et
le tagger fait mieux ce qu'il faisait.
"""

from __future__ import annotations

from reference.lines import PhysicalLine
from reference.structure import _rightmost_price, merge_price_fragments


class PricedLine:
    """Une ligne fusionnée porteuse d'un prix, et sa place dans le ticket."""

    def __init__(self, index: int, line: PhysicalLine, price: float, word):
        self.index = index
        self.line = line
        self.price = price
        self.word = word

    @property
    def label(self) -> str:
        return " ".join(
            w.text for w in self.line.words if w is not self.word
        ).strip()


def priced_lines(merged: list[PhysicalLine]) -> list[PricedLine]:
    result = []
    for index, line in enumerate(merged):
        priced = _rightmost_price(line)
        if priced is not None:
            result.append(PricedLine(index, line, priced[0], priced[1]))
    return result


def merged_lines(raw_lines: list[PhysicalLine]) -> list[PhysicalLine]:
    return [merge_price_fragments(line) for line in raw_lines]
