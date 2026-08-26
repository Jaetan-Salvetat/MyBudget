"""La métrique produit : un ticket est bon, ou il ne l'est pas.

`count_edits` (bench/flow.py) compte des montants et ignore tout le reste. Il
mesure ce que le checksum protège — la somme — et c'est son rôle. Mais
l'utilisateur ne voit pas une somme : il voit une enseigne, une date, et une
liste d'articles nommés. Le nom décide de la catégorie, donc de la ligne de
budget ; la date décide du mois ; l'enseigne nomme la dépense. Une extraction
dont les montants sont justes et les libellés décalés d'une ligne est comptée
parfaite là-bas, et fausse ici.

**Un ticket n'est exact que si tout l'est** : enseigne, date, total, et chaque
article apparié sur (nom, montant net) sans article en trop ni manquant. Une
seule erreur invalide le ticket entier — la moyenne d'erreurs cache justement
ce qui compte, parce qu'une erreur unique suffit à fausser un budget.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field
from difflib import SequenceMatcher

AMOUNT_EPSILON = 0.005
NAME_SIMILARITY_THRESHOLD = 0.75
STORE_SIMILARITY_THRESHOLD = 0.6
MIN_MEANINGFUL_LENGTH = 3
NON_ALPHANUMERIC = re.compile(r"[^A-Z0-9]+")

STORE = "enseigne"
DATE = "date"
TOTAL = "total"
ITEMS = "articles"


@dataclass(frozen=True)
class ExtractedName:
    name: str
    amount: float
    discount: float = 0.0

    @property
    def net(self) -> float:
        return round(self.amount - self.discount, 2)


@dataclass(frozen=True)
class Exactness:
    """Ce qui diverge, pour savoir où investir. `exact` est la métrique."""

    wrong: list[str] = field(default_factory=list)

    @property
    def exact(self) -> bool:
        return not self.wrong


def normalize_name(name: str | None) -> str:
    """Majuscules sans accent ni ponctuation : l'OCR n'est pas jugé ici, le
    rattachement libellé ↔ prix l'est."""
    if not name:
        return ""
    folded = "".join(
        char
        for char in unicodedata.normalize("NFD", name.upper())
        if not unicodedata.combining(char)
    )
    return NON_ALPHANUMERIC.sub(" ", folded).strip()


def _similar(left: str, right: str, threshold: float) -> bool:
    if not left or not right:
        return False
    if len(left) < MIN_MEANINGFUL_LENGTH or len(right) < MIN_MEANINGFUL_LENGTH:
        return left == right
    return SequenceMatcher(None, left, right).ratio() >= threshold


def name_matches(extracted: str, expected: str) -> bool:
    """Deux libellés désignent le même article.

    Tolérant aux dégâts de l'OCR (« 120GENU » pour « 120GENV ») et à un
    libellé plus court que la vérité : l'OCR coupe une ligne, la colonne coupe
    une référence, et ce qui manque ne trompe personne.

    Intolérant à un **mot de plus** que la vérité. Une classe de TVA, une
    quantité ou un code imprimé dans une autre colonne n'a pas sa place dans
    un nom : c'est ce nom que l'utilisateur lit et que la catégorisation
    reçoit. Le seuil de similarité seul ne sait pas les séparer — « 140G
    1ARTE POMMES » (dégât OCR) tombe à 0,90 et « MPDC MARQUE PAG 2 20 1 »
    (résidu de colonne) à 0,80. Le compte de mots, lui, tranche."""
    left, right = normalize_name(extracted), normalize_name(expected)
    if len(left.split()) > len(right.split()):
        return False
    return _similar(left, right, NAME_SIMILARITY_THRESHOLD)


def store_matches(extracted: str | None, expected: str | None) -> bool:
    """L'enseigne est lue sur un logo déformé et le golden la nomme
    proprement (« city » pour « CARREFOUR CITY ») : on accepte qu'un nom soit
    contenu dans l'autre, on refuse deux enseignes différentes."""
    left, right = normalize_name(extracted), normalize_name(expected)
    if not left or not right:
        return left == right
    if left in right or right in left:
        return True
    return _similar(left, right, STORE_SIMILARITY_THRESHOLD)


def items_match(
    extracted: list[ExtractedName], expected: list[ExtractedName]
) -> bool:
    """Chaque article extrait s'apparie à un attendu sur (nom, montant net).

    L'appariement se fait par montant puis par nom, et privilégie les couples
    dont le nom concorde : deux articles au même prix ne doivent pas rendre un
    ticket faux à cause de leur ordre."""
    if len(extracted) != len(expected):
        return False
    remaining = list(expected)
    for item in extracted:
        matched = next(
            (
                candidate
                for candidate in remaining
                if abs(candidate.net - item.net) < AMOUNT_EPSILON
                and name_matches(item.name, candidate.name)
            ),
            None,
        )
        if matched is None:
            return False
        remaining.remove(matched)
    return not remaining


def receipt_exactness(
    store: str | None,
    date: str | None,
    total: float | None,
    items: list[ExtractedName],
    golden: dict,
) -> Exactness:
    """Confronte une lecture complète au golden. Tout doit tomber juste."""
    expected = golden["receipt"]
    wrong = []
    if not store_matches(store, expected.get("store")):
        wrong.append(STORE)
    if (date or None) != (expected.get("date") or None):
        wrong.append(DATE)
    expected_total = expected.get("total")
    if expected_total is None or total is None:
        if expected_total is not None or total is not None:
            wrong.append(TOTAL)
    elif abs(total - float(expected_total)) >= AMOUNT_EPSILON:
        wrong.append(TOTAL)
    golden_items = [
        ExtractedName(
            name=item.get("name") or "",
            amount=float(item["amount"]),
            discount=float(item.get("discount") or 0.0),
        )
        for item in expected["items"]
    ]
    if not items_match(items, golden_items):
        wrong.append(ITEMS)
    return Exactness(wrong=wrong)
