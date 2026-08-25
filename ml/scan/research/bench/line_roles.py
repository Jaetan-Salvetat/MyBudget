"""Ce que le classifieur de lignes actuel vaut sur le corpus annoté.

Le classifieur `line_clf_v3` n'étiquette que les lignes porteuses de prix,
en 5 classes ; le corpus annote toutes les lignes en 12 rôles. La
comparaison se fait donc sur l'intersection : les lignes à prix, rôles
annotés ramenés aux 5 classes du modèle. C'est la barre que son remplaçant
doit franchir, et elle est mesurée sur un jeu qu'il n'a jamais vu.

    uv run python -m bench.line_roles [--held-out]
"""

from __future__ import annotations

import sys
from collections import Counter

import numpy as np

from annotate.dataset import AnnotatedReceipt, load
from annotate.schema import (
    DISCOUNT,
    ITEM,
    PAYMENT,
    SUBTOTAL,
    TOTAL,
)
from reference.line_features import merged_lines
from reference.line_labels import CLASS_NAMES
from reference.line_labels import DISCOUNT as CLASS_DISCOUNT
from reference.line_labels import IGNORE as CLASS_IGNORE
from reference.line_labels import ITEM as CLASS_ITEM
from reference.line_labels import PAYMENT as CLASS_PAYMENT
from reference.line_labels import TOTAL as CLASS_TOTAL
from reference.structure_ml import load_classifier

ROLE_TO_CLASS = {
    ITEM: CLASS_ITEM,
    DISCOUNT: CLASS_DISCOUNT,
    TOTAL: CLASS_TOTAL,
    SUBTOTAL: CLASS_TOTAL,
    PAYMENT: CLASS_PAYMENT,
}


def _pairs(receipt: AnnotatedReceipt, featurize) -> tuple[list[int], list[list[float]]]:
    """Le classifieur travaille sur les lignes fusionnées : l'index d'une
    ligne fusionnée est celui de la ligne brute dont elle vient."""
    merged = merged_lines(receipt.lines)
    priced, rows = featurize(merged)
    expected = []
    features = []
    for line, row in zip(priced, rows):
        if line.index >= len(receipt.roles):
            continue
        expected.append(ROLE_TO_CLASS.get(receipt.roles[line.index], CLASS_IGNORE))
        features.append(row)
    return expected, features


def main(argv: list[str]) -> int:
    receipts = load(held_out="--held-out" in argv)
    model, featurize = load_classifier()

    expected: list[int] = []
    features: list[list[float]] = []
    for receipt in receipts:
        truth, rows = _pairs(receipt, featurize)
        expected.extend(truth)
        features.extend(rows)

    if not features:
        print("aucune ligne à prix dans le corpus chargé")
        return 1
    predicted = model.predict(np.array(features))
    truth = np.array(expected)

    jeu = "évaluation" if "--held-out" in argv else "entraînement"
    print(f"=== classifieur actuel sur le corpus annoté ({jeu})")
    print(f"  {len(receipts)} tickets, {len(truth)} lignes à prix")
    print(f"  exactitude : {(predicted == truth).mean():.1%}")
    for index, name in enumerate(CLASS_NAMES):
        mask = truth == index
        if not mask.any():
            continue
        recall = (predicted[mask] == index).mean()
        confusions = Counter(
            CLASS_NAMES[value] for value in predicted[mask] if value != index
        )
        detail = ", ".join(f"{k} {v}" for k, v in confusions.most_common(3))
        print(f"  {name:<9} rappel {recall:.1%} sur {int(mask.sum()):>5}   {detail}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
