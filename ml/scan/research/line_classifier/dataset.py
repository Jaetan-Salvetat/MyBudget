"""Du corpus annoté aux exemples d'entraînement du classifieur de lignes.

Le classifieur ne voit que les lignes porteuses de prix, sur les lignes
*fusionnées* — c'est son entrée à l'inférence, ce doit être son entrée à
l'entraînement. Chaque ligne à prix reçoit le rôle annoté de la ligne brute
dont elle vient, projeté sur les 5 classes du contrat.
"""

from __future__ import annotations

import numpy as np

from annotate.dataset import AnnotatedReceipt
from reference.line_features import merged_lines
from reference.line_labels import IGNORE, ROLE_TO_CLASS


def labelled_lines(
    receipts: list[AnnotatedReceipt], featurize
) -> tuple[np.ndarray, np.ndarray]:
    features: list[list[float]] = []
    labels: list[int] = []
    for receipt in receipts:
        priced, rows = featurize(merged_lines(receipt.lines))
        for line, row in zip(priced, rows):
            if line.index >= len(receipt.roles):
                continue
            features.append(row)
            labels.append(ROLE_TO_CLASS.get(receipt.roles[line.index], IGNORE))
    return np.array(features), np.array(labels)
