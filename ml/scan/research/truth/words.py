"""Vérité au niveau du mot : ce que l'annotation dit sans passer par la ligne.

`truth/spans.py` répond à la même question, mais sur les lignes que
`cluster_lines` a fabriquées — un recouvrement vertical de 0,4, une boîte qui
grandit à chaque mot ajouté, un tri par abscisse. Cette décision-là est écrite
à la main, elle est irréversible, et tous les modèles en dépendent : mesuré
sur la tranche d'évaluation, 5,8 % des lignes de trois mots ou plus fusionnent
deux rangées du ticket et en entrelacent les mots. Un nom dont les mots ne
sont plus contigus ne peut alors être écrit par aucun intervalle.

Ici la ligne n'existe pas. Le nom est **l'ensemble des mots qui l'écrivent**,
le montant est **le mot qui le porte**, et rien d'autre n'est décidé.

Deux tolérances, et elles vivent dans la vérité, pas dans le flow — c'est le
rôle que le seuil d'alignement joue déjà pour les spans, et que le checksum
joue pour les montants : **elles éliminent, elles ne réparent pas.**

- une rangée est ce qui tient dans une demi-hauteur de mot autour d'une ancre,
  et l'ancre change à chaque mot : aucune partition n'est figée, donc aucune
  erreur de regroupement n'est propagée ;
- un nom n'est retenu que s'il se lit presque à l'identique (`ALIGNMENT_THRESHOLD`).

La lecture d'un montant, elle, n'a qu'une règle : le motif décimal que porte
le mot. Ce qui l'entoure — devise collée, code de TVA, caractère parasite — ne
la concerne pas. Désigner le bon mot est une question de modèle ; mesuré sur
la tranche d'évaluation, la règle actuelle (« le mot le plus à droite qu'une
regex accepte ») rend le bon montant sur 91,2 % des articles, là où le mot
juste existe dans 95,6 % des cas.
"""

from __future__ import annotations

import re
import statistics
from dataclasses import dataclass
from difflib import SequenceMatcher

from reference.lines import Word
from truth.spans import ALIGNMENT_THRESHOLD, fold

# Une rangée du ticket, mesurée en hauteurs de mot autour de l'ancre.
ROW_TOLERANCE = 0.5

AMOUNT_EPSILON = 0.005
DECIMAL_PATTERN = re.compile(r"-?\d{1,4}[.,]\d{2}")


def _median_height(words: list[Word]) -> float:
    return statistics.median(word.bottom - word.top for word in words) or 1.0


def rows(words: list[Word]) -> list[tuple[int, ...]]:
    """Les rangées candidates : autour de chaque mot, ce qui partage sa bande,
    trié par abscisse. Une même rangée vue de deux ancres ne compte qu'une
    fois.

    Ce n'est pas une partition : les rangées se chevauchent, et c'est ce qui
    les rend inoffensives. Un regroupement figé propage ses erreurs à tout
    l'aval ; un ensemble de candidates laisse l'aval trancher."""
    if not words:
        return []
    tolerance = _median_height(words) * ROW_TOLERANCE
    seen: set[tuple[int, ...]] = set()
    for anchor in words:
        row = tuple(
            sorted(
                (
                    index
                    for index, word in enumerate(words)
                    if abs(word.center_y - anchor.center_y) <= tolerance
                ),
                key=lambda index: words[index].left,
            )
        )
        seen.add(row)
    return list(seen)


def name_words(
    words: list[Word], expected: str, candidates: list[tuple[int, ...]] | None = None
) -> tuple[int, ...] | None:
    """Les mots qui écrivent `expected`, ou None si le ticket ne le porte pas
    assez fidèlement.

    À ressemblance égale, l'ensemble le plus court gagne, puis le plus à
    gauche : un mot répété ne doit pas faire avaler ce qui le sépare de son
    jumeau. `candidates` évite de recalculer les rangées à chaque nom."""
    target = fold(expected)
    if not target or not words:
        return None
    folded = [fold(word.text) for word in words]
    best: tuple[float, int, int] | None = None
    found: tuple[int, ...] | None = None
    for row in candidates if candidates is not None else rows(words):
        for start in range(len(row)):
            for end in range(start + 1, len(row) + 1):
                taken = row[start:end]
                candidate = " ".join(
                    part for part in (folded[index] for index in taken) if part
                ).strip()
                if not candidate:
                    continue
                ratio = SequenceMatcher(None, candidate, target).ratio()
                score = (ratio, -(end - start), -taken[0])
                if best is None or score > best:
                    best = score
                    found = taken
    if best is None or best[0] < ALIGNMENT_THRESHOLD:
        return None
    return found


def read_amount(text: str) -> float | None:
    """Le montant que porte ce mot, en valeur absolue. Une seule règle."""
    match = DECIMAL_PATTERN.search(text.replace(" ", ""))
    if match is None:
        return None
    return abs(float(match.group(0).replace(",", ".")))


def amount_word(
    words: list[Word], amount: float, within: tuple[int, ...] | None = None
) -> int | None:
    """Le mot qui porte ce montant, ou None si aucun ne le porte — ou si
    plusieurs le portent.

    L'ambiguïté est un refus, jamais un choix : deux mots au même montant
    laissent la question sans réponse, et deviner ici fabriquerait une vérité
    que rien ne vérifie. `within` restreint les candidats — c'est ce qui lève
    l'ambiguïté sans rien deviner, quand l'appelant sait sur quelle rangée
    l'article est imprimé."""
    target = abs(amount)
    searched = range(len(words)) if within is None else within
    carriers = [
        index
        for index in searched
        if (read := read_amount(words[index].text)) is not None
        and abs(read - target) < AMOUNT_EPSILON
    ]
    return carriers[0] if len(carriers) == 1 else None


@dataclass(frozen=True)
class ItemTruth:
    """Un article, dit en mots : ceux qui le nomment, celui qui le chiffre."""

    name_words: tuple[int, ...]
    amount_word: int | None


def item_truth(
    words: list[Word],
    name: str,
    amount: float | None,
    candidates: list[tuple[int, ...]] | None = None,
) -> ItemTruth | None:
    """L'article que décrivent ce nom et ce montant, ou None si le ticket ne
    porte pas le nom.

    Le montant se cherche d'abord sur la rangée qui porte le nom — c'est elle
    qui départage un prix unitaire imprimé ailleurs — puis sur le ticket
    entier quand la rangée n'en porte aucun. Ce qui reste ambigu reste sans
    réponse : un article peut être nommé sans que son mot porteur soit connu,
    et la vérité le dit plutôt que de choisir."""
    rows_of = candidates if candidates is not None else rows(words)
    named = name_words(words, name, rows_of)
    if named is None:
        return None
    if amount is None:
        return ItemTruth(name_words=named, amount_word=None)
    row = next((row for row in rows_of if set(named) <= set(row)), named)
    carrier = amount_word(words, amount, within=row)
    if carrier is None:
        carrier = amount_word(words, amount)
    return ItemTruth(name_words=named, amount_word=carrier)
