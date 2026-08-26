"""Rattachement du libellé à son article : quelle ligne, puis quels mots.

Les règles cherchaient le libellé d'un article sur sa propre ligne, et à
défaut sur la dernière ligne sans prix rencontrée. Quand le prix est imprimé
sur sa propre ligne — pesée, quantité, code-barres — elles ramassaient ce qui
traînait autour : « 0,792 kg 2,65 €/kg » au lieu de « POIRE CONFERENCE ».

**Les deux décisions reviennent à des modèles, pas à des réglages.** La
première — *quelle ligne* — était un recul d'une ligne et un seuil de
confiance choisis à la main ; `train_link` l'apprend. La seconde — *quels
mots de cette ligne* — était une coupe de colonne unique et quatre
expressions régulières ; `train_span` l'apprend. Mesuré sur T1-test, 78 % des
libellés faux venaient de cette seconde décision : un code article devant,
une quantité ou un prix unitaire derrière, sur la bonne ligne.
"""

from __future__ import annotations

import joblib
import numpy as np

from paths import LINK_MODEL_PATH
from reference.line_features_all import featurize, window
from reference.lines import PhysicalLine
from reference.spans_ml import label_of
from reference.structure import ExtractedItem

_model = None


def load_link_model():
    global _model
    if _model is None:
        _model = joblib.load(LINK_MODEL_PATH)
    return _model


def label_offsets(lines: list[PhysicalLine]) -> np.ndarray:
    """Pour chaque ligne, la distance qui la sépare du libellé de l'article
    dont elle porte le prix — 0 quand ce libellé est sur elle-même."""
    rows = featurize(lines)
    if not rows:
        return np.zeros(0, dtype=int)
    stacked = np.array([window(rows, index) for index in range(len(rows))])
    return load_link_model().predict(stacked)


def relabel(
    items: list[ExtractedItem],
    lines: list[PhysicalLine],
    offsets: np.ndarray,
    probabilities: list[list[float]],
) -> list[ExtractedItem]:
    """Donne à chaque article les mots que les modèles désignent.

    Les lignes déportées sont consommées dans l'ordre des articles, chacune
    une seule fois : deux articles ne partagent pas un nom. La ligne du prix,
    elle, appartient à son article — elle n'a pas à être réservée."""
    if not len(offsets):
        return items
    used: set[int] = set()
    for item in items:
        if item.line_index is None or item.line_index >= len(offsets):
            continue
        carrier = item.line_index - int(offsets[item.line_index])
        if not 0 <= carrier < len(lines) or carrier >= len(probabilities):
            continue
        deported = carrier != item.line_index
        if deported and carrier in used:
            continue
        label = label_of(lines[carrier], probabilities[carrier])
        if label is None:
            continue
        item.name = label
        if deported:
            used.add(carrier)
    return items
