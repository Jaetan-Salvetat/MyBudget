"""Rattachement du libellé à son article, guidé par le tagger de rôles.

Les règles cherchent le libellé d'un article sur sa propre ligne, et à défaut
sur la dernière ligne sans prix rencontrée. Mesuré sur T1-test : 84 tickets
sur 500 ont tous leurs montants justes et un libellé venu de la mauvaise
ligne — code-barres, ligne de promotion, mention de fidélité.

Le tagger sait dire qu'une ligne est un `item_label` : un libellé d'article
dont le prix est imprimé ailleurs. On s'en sert pour corriger, jamais pour
écraser — un libellé déjà parlant est laissé tel quel, parce que le tagger se
trompe une fois sur six et que le nom décide de la catégorie.
"""

from __future__ import annotations

import re

import numpy as np

from annotate.schema import ITEM_LABEL, ROLES
from reference.lines import PhysicalLine
from reference.structure import ExtractedItem, _clean_name, _plausible_label

MIN_LABEL_PROBABILITY = 0.5
MAX_LOOKBACK = 3
MIN_NAMING_LETTERS = 3

# Ce qu'un ticket imprime à côté d'un prix sans que ça nomme quoi que ce
# soit : devise, régime de taxe, code de TVA en fin de ligne.
NON_NAMING_TOKENS = frozenset(
    {"EUR", "EURO", "EUROS", "USD", "HT", "TTC", "TVA", "A", "B", "C", "D", "X"}
)
NON_LETTERS = re.compile(r"[^A-Za-zÀ-ÿ]+")


def _weak(name: str) -> bool:
    """Un libellé qui ne nomme rien.

    « EUR », « A », un code-barres seul : le prix était sur sa propre ligne et
    les règles ont ramassé ce qui traînait autour. C'est le seul cas où l'avis
    du tagger doit primer sur le leur — un vrai nom de produit, même abîmé,
    vaut mieux qu'un nom deviné."""
    words = [
        word
        for word in NON_LETTERS.sub(" ", name).upper().split()
        if word not in NON_NAMING_TOKENS
    ]
    return sum(len(word) for word in words) < MIN_NAMING_LETTERS


def relabel(
    items: list[ExtractedItem],
    lines: list[PhysicalLine],
    probabilities: np.ndarray,
) -> list[ExtractedItem]:
    """Remplace les libellés faibles par la ligne `item_label` la plus proche
    au-dessus, chacune ne servant qu'une fois — deux articles ne partagent
    pas un nom."""
    if not len(probabilities):
        return items
    column = probabilities[:, ROLES.index(ITEM_LABEL)]
    used: set[int] = set()
    for item in items:
        if item.line_index is None or not _weak(item.name):
            continue
        for offset in range(1, MAX_LOOKBACK + 1):
            candidate = item.line_index - offset
            if candidate < 0:
                break
            if candidate in used or column[candidate] < MIN_LABEL_PROBABILITY:
                continue
            label = _plausible_label(lines[candidate].text)
            if label is not None:
                item.name = _clean_name(label)
                used.add(candidate)
                break
    return items
