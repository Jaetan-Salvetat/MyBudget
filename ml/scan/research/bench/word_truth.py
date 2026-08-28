"""Ce que la vérité devient quand la ligne disparaît.

Tous les modèles du flow sont conditionnés sur `cluster_lines` : un
recouvrement vertical de 0,4, une boîte qui grandit à chaque mot ajouté, un
tri par abscisse. Cette décision est écrite à la main, elle précède tout
apprentissage, et elle est irréversible — un nom dont les mots ont été
entrelacés avec ceux de la rangée voisine ne peut plus être écrit par aucun
intervalle de mots contigus.

Ce bench mesure ce que ça coûte, et ce que ça coûterait de s'en passer. Aucun
modèle n'intervient : il confronte la vérité annotée à ce que chaque
formulation peut, au mieux, en récupérer.

- **le nom** : un intervalle contigu d'une ligne construite (`truth.spans`),
  contre l'ensemble des mots qui l'écrivent (`truth.words`) ;
- **le montant** : le mot le plus à droite qu'une regex accepte
  (`structure._rightmost_price`), contre le mot qui porte le montant, lu par
  une règle unique (`truth.words.amount_word`).

Les deux colonnes sont des plafonds. Elles disent où un modèle parfait
s'arrêterait, donc si le travail restant est dans les modèles ou avant eux.

    uv run python -m bench.word_truth [--corpus=open_prices] [--limit=N]
"""

from __future__ import annotations

import sys
from collections import Counter

from annotate.dataset import AnnotatedReceipt, load
from annotate.schema import ITEM
from reference.lines import PhysicalLine, Word
from reference.structure import _rightmost_price, merge_price_fragments
from truth.spans import align
from truth.words import AMOUNT_EPSILON, item_truth, read_amount, rows

DEFAULT_CORPUS = "open_prices"


def carries(word: Word, amount: float) -> bool:
    read = read_amount(word.text)
    return read is not None and abs(read - abs(amount)) < AMOUNT_EPSILON


def _words(lines: list[PhysicalLine]) -> list[Word]:
    return [word for line in lines for word in line.words]


def _items(receipt: AnnotatedReceipt) -> list[tuple[int, str | None, float | None]]:
    """Les articles annotés : ligne du prix, nom, montant."""
    return [
        (index, receipt.names[index], receipt.amounts[index])
        for index, role in enumerate(receipt.roles)
        if role == ITEM
    ]


def _carrier(receipt: AnnotatedReceipt, index: int) -> int:
    target = receipt.label_indexes[index]
    return index if target is None else target


def score(receipt: AnnotatedReceipt) -> Counter[str]:
    """Ce que chaque formulation récupère sur ce ticket."""
    tally: Counter[str] = Counter()
    words = _words(receipt.lines)
    if not words:
        return tally
    candidates = rows(words)
    merged = [merge_price_fragments(line) for line in receipt.lines]

    for index, name, amount in _items(receipt):
        priced = amount is not None and abs(amount) >= AMOUNT_EPSILON
        found = item_truth(words, name, amount, candidates) if name else None

        if name:
            tally["noms"] += 1
            carrier = _carrier(receipt, index)
            if 0 <= carrier < len(receipt.lines) and align(
                receipt.lines[carrier], name
            ):
                tally["noms — ligne construite"] += 1
            if found is not None:
                tally["noms — mots du ticket"] += 1

        if priced:
            tally["montants"] += 1
            read = _rightmost_price(merged[index])
            if read is not None and abs(abs(read[0]) - abs(amount)) < AMOUNT_EPSILON:
                tally["montants — regex, mot le plus à droite"] += 1
            if any(carries(word, amount) for word in words):
                tally["montants — un mot du ticket le porte"] += 1
            if found is not None and found.amount_word is not None:
                tally["montants — un seul mot le porte"] += 1
    return tally


def run(corpus: str, limit: int | None) -> Counter[str]:
    receipts = [
        receipt
        for receipt in load(held_out=True, roles_only=True)
        if receipt.corpus == corpus
    ]
    total: Counter[str] = Counter()
    for receipt in receipts[:limit] if limit else receipts:
        total["tickets"] += 1
        total.update(score(receipt))
    return total


def report(tally: Counter[str]) -> None:
    if not tally["tickets"]:
        print("aucun ticket à juger")
        return
    print(f"\n=== {tally['tickets']} tickets d'évaluation, vérité annotée")
    for subject, formulations in (
        ("noms", ("ligne construite", "mots du ticket")),
        (
            "montants",
            (
                "regex, mot le plus à droite",
                "un mot du ticket le porte",
                "un seul mot le porte",
            ),
        ),
    ):
        base = tally[subject]
        print(f"\n  {subject} annotés : {base}")
        for formulation in formulations:
            found = tally[f"{subject} — {formulation}"]
            print(f"    {formulation:<30}{found:>6}  ({found / max(base, 1):.2%})")


def main(argv: list[str]) -> int:
    corpus, limit = DEFAULT_CORPUS, None
    for argument in argv:
        if argument.startswith("--corpus="):
            corpus = argument.split("=", 1)[1]
        elif argument.startswith("--limit="):
            limit = int(argument.split("=", 1)[1])
    report(run(corpus, limit))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
