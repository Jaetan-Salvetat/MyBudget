"""Vérité de span : les mots d'une ligne qui composent le libellé d'un article.

Le corpus annoté dit *quelle ligne* porte le libellé, jamais *quels mots* : la
question ne lui a jamais été posée. Le golden, lui, porte le libellé écrit —
et l'aligner sur les mots de la ligne désignée reconstruit la réponse.

L'alignement est délibérément strict. Un libellé n'est retenu que s'il se lit
presque à l'identique sur la ligne : ce qui a été abîmé par l'OCR
n'enseignerait au modèle qu'une frontière inventée. Le filtre joue ici le rôle
que le checksum joue pour les montants — il élimine, il ne répare pas.

Le repli d'accents est refait ici plutôt qu'emprunté à la métrique
(`bench/exactness.py`) : la vérité et le juge doivent rester deux chaînes
indépendantes, sinon un défaut commun se cache dans les deux.
"""

from __future__ import annotations

import re
import unicodedata
from difflib import SequenceMatcher

from annotate.dataset import AnnotatedReceipt
from annotate.schema import ITEM
from reference.lines import PhysicalLine

# Au-dessous, la ligne n'a pas été lue assez fidèlement pour dire où le
# libellé commence et où il finit.
ALIGNMENT_THRESHOLD = 0.95
AMOUNT_EPSILON = 0.005
NON_ALPHANUMERIC = re.compile(r"[^A-Z0-9]+")


def fold(text: str) -> str:
    """Majuscules sans accent ni ponctuation, mots séparés par une espace."""
    stripped = "".join(
        char
        for char in unicodedata.normalize("NFD", text.upper())
        if not unicodedata.combining(char)
    )
    return NON_ALPHANUMERIC.sub(" ", stripped).strip()


def align(line: PhysicalLine, expected: str) -> tuple[int, int] | None:
    """L'intervalle de mots `[début, fin)` qui écrit `expected` sur cette
    ligne, ou None si la ligne ne le porte pas assez fidèlement.

    À égalité de ressemblance, l'intervalle le plus court gagne : un mot
    répété ne doit pas faire avaler ce qui le sépare de son jumeau."""
    target = fold(expected)
    if not target or not line.words:
        return None
    folded = [fold(word.text) for word in line.words]
    best: tuple[float, int, int, int] | None = None
    for start in range(len(folded)):
        for end in range(start + 1, len(folded) + 1):
            candidate = " ".join(part for part in folded[start:end] if part).strip()
            if not candidate:
                continue
            ratio = SequenceMatcher(None, candidate, target).ratio()
            score = (ratio, -(end - start), -start, start)
            if best is None or score > best:
                best = score
                span = (start, end)
    if best is None or best[0] < ALIGNMENT_THRESHOLD:
        return None
    return span


def _expected_name(golden_items: list[dict], amount: float | None) -> str | None:
    """Le libellé du seul article du golden qui porte ce montant imprimé.

    Deux articles au même prix rendent la question sans réponse : leurs
    libellés diffèrent et rien ne dit lequel va à cette ligne-ci."""
    if amount is None:
        return None
    matches = [
        item
        for item in golden_items
        if abs(float(item["amount"]) - amount) < AMOUNT_EPSILON
    ]
    if len(matches) != 1:
        return None
    return matches[0].get("name")


def spans_of(
    receipt: AnnotatedReceipt, golden_items: list[dict]
) -> list[tuple[int, int, int]]:
    """Pour chaque article dont le libellé s'aligne sans ambiguïté :
    `(index de la ligne qui le porte, début, fin)`."""
    found = []
    for index, role in enumerate(receipt.roles):
        if role != ITEM:
            continue
        expected = _expected_name(golden_items, receipt.amounts[index])
        if not expected:
            continue
        target = receipt.label_indexes[index]
        carrier = index if target is None else target
        if not 0 <= carrier < len(receipt.lines):
            continue
        span = align(receipt.lines[carrier], expected)
        if span is not None:
            found.append((carrier, *span))
    return found


def spans_from_golden(
    lines: list[PhysicalLine], golden_items: list[dict]
) -> list[tuple[int, int, int]]:
    """Pour chaque libellé du golden, la ligne qui l'écrit et son intervalle
    de mots — sans passer par l'annotation de rôles.

    Le corpus annoté ne couvre pas tous les tickets et rejette ceux dont un
    montant est illisible ; le golden, lui, nomme les articles de tous. Faire
    la vérité depuis le libellé seul rend ces tickets à l'entraînement, et
    avec eux les découpages rares — un nombre en tête, une colonne à gauche.

    Un libellé n'est retenu que si le ticket l'écrit **autant de fois que le
    golden le vend** : deux lignes pour un article laissent le doute sur celle
    qui le nomme."""
    found: list[tuple[int, int, int]] = []
    wanted: dict[str, int] = {}
    for item in golden_items:
        name = fold(item.get("name") or "")
        if name:
            wanted[name] = wanted.get(name, 0) + 1
    for name, count in wanted.items():
        matches = [
            (index, *span)
            for index, line in enumerate(lines)
            if (span := align(line, name)) is not None
        ]
        if len(matches) == count:
            found.extend(matches)
    return sorted(found)
