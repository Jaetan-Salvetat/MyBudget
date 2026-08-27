"""La métrique produit : un ticket est bon, ou il ne l'est pas — et toutes les
erreurs ne se valent pas.

`count_edits` (bench/scoring.py) compte des montants et ignore tout le reste. Il
mesure ce que le checksum protège — la somme — et c'est son rôle. Mais
l'utilisateur ne voit pas une somme : il voit une enseigne, une date, et une
liste d'articles nommés. Une extraction dont les montants sont justes et les
libellés décalés d'une ligne est comptée parfaite là-bas, et fausse ici.

**Un ticket n'est exact que si tout l'est** : enseigne, date, total, et chaque
article apparié sur (nom, montant net) sans article en trop ni manquant.

Mais l'exactitude seule guide mal. Un montant faux, une enseigne fausse, une
date fausse **se voient** : ils sont affichés en clair à côté d'un ticket que
l'utilisateur a encore en main, et se corrigent en deux gestes. Un libellé
posé sur le mauvais article et un article absent, eux, **ne se voient pas** —
la ligne a l'air normale, la somme tombe juste, et rien n'attire l'œil. Ces
deux-là partent silencieusement dans le budget.

D'où deux niveaux, comptés séparément : `silent` porte ce que l'utilisateur ne
peut pas rattraper, et c'est lui qu'il faut faire tomber à zéro — sur les
tickets *vérifiés* d'abord, puisque ceux-là ne passent par aucun écran de
confirmation.
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

# Ce que l'utilisateur ne verra pas : le nom appartient à l'article d'à côté,
# ou l'article n'est nulle part.
LABEL = "libellé"
MISSING = "article manquant"
EXTRA = "article en trop"
SILENT = (LABEL, MISSING, EXTRA)

# Ce qu'il lit et corrige, ticket en main.
AMOUNT = "montant"
STORE = "enseigne"
DATE = "date"
TOTAL = "total"

# Le nom attendu, plus quelque chose : un calibre, un code de TVA, un préfixe
# d'enseigne. Ce n'est pas juste — le nom doit être le nom — mais ce n'est pas
# silencieux non plus : l'utilisateur a le bon produit sous les yeux et la
# catégorisation reçoit le bon produit. Rien ne lui est caché, donc il n'a rien
# à relire, et c'est ce que `SILENT` mesure.
#
# L'inclusion inverse n'en est pas : un nom rogné (« YAOURT » pour « YAOURT
# MYRTILLE ») peut désigner un autre produit de la même famille, et rien ne
# permet de s'en apercevoir. Elle reste un libellé faux.
WIDE = "libellé large"


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
    """Ce qui diverge, pour savoir où investir.

    `exact` est la métrique du ticket, `silent` la part que l'utilisateur ne
    peut pas rattraper, `counts` le nombre d'articles par type d'erreur."""

    wrong: list[str] = field(default_factory=list)
    counts: dict[str, int] = field(default_factory=dict)

    @property
    def exact(self) -> bool:
        return not self.wrong

    @property
    def silent(self) -> list[str]:
        return [field_name for field_name in self.wrong if field_name in SILENT]


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


def name_widens(extracted: str, expected: str) -> bool:
    """Le nom rendu porte tout le nom attendu, et davantage.

    L'inclusion se juge sur des **mots entiers** : « WASA FIBRE » ne contient
    pas « WASA FIBRES », et laisser passer un préfixe ferait de tout nom
    tronqué un nom large."""
    left, right = normalize_name(extracted).split(), normalize_name(expected).split()
    if not left or not right or len(left) <= len(right):
        return False
    return any(
        left[start : start + len(right)] == right
        for start in range(len(left) - len(right) + 1)
    )


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


def _take(
    items: list[ExtractedName],
    candidates: list[ExtractedName],
    fits,
) -> int:
    """Apparie et retire tout ce qui concorde, et rend le compte."""
    paired = 0
    for item in list(items):
        matched = next(
            (candidate for candidate in candidates if fits(item, candidate)), None
        )
        if matched is None:
            continue
        items.remove(item)
        candidates.remove(matched)
        paired += 1
    return paired


def compare_items(
    extracted: list[ExtractedName], expected: list[ExtractedName]
) -> list[str]:
    """Ce qui cloche sur les articles, un verdict par article.

    L'appariement va du plus sûr au moins sûr : le couple complet d'abord —
    deux articles au même prix ne doivent pas fabriquer deux libellés faux à
    cause de leur ordre — puis le montant seul, puis le nom seul. Ce qui
    reste d'un côté manque, ce qui reste de l'autre est en trop.

    Un article apparié par son montant mais pas par son nom est un **libellé
    faux** : la somme tombe juste et rien ne se voit. Apparié par son nom mais
    pas par son montant, c'est un **montant faux** : le nom désigne la ligne à
    relire.

    Entre les deux passes de nom, celle des noms **larges** : le nom attendu y
    est tout entier, avec un calibre ou un code en plus. Elle passe avant
    l'appariement au montant seul, sinon deux articles au même prix se
    voleraient leur nom et fabriqueraient deux libellés faux là où il n'y a
    qu'un nom trop large."""
    left, right = list(extracted), list(expected)
    _take(
        left,
        right,
        lambda a, b: (
            abs(a.net - b.net) < AMOUNT_EPSILON and name_matches(a.name, b.name)
        ),
    )
    wide = _take(
        left,
        right,
        lambda a, b: (
            abs(a.net - b.net) < AMOUNT_EPSILON and name_widens(a.name, b.name)
        ),
    )
    labels = _take(left, right, lambda a, b: abs(a.net - b.net) < AMOUNT_EPSILON)
    amounts = _take(left, right, lambda a, b: name_matches(a.name, b.name))
    return [
        *[WIDE] * wide,
        *[LABEL] * labels,
        *[AMOUNT] * amounts,
        *[EXTRA] * len(left),
        *[MISSING] * len(right),
    ]


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
    verdicts = compare_items(items, golden_items)
    counts: dict[str, int] = {}
    for verdict in verdicts:
        counts[verdict] = counts.get(verdict, 0) + 1
    wrong.extend(
        name for name in (LABEL, WIDE, AMOUNT, EXTRA, MISSING) if name in counts
    )
    return Exactness(wrong=wrong, counts=counts)
