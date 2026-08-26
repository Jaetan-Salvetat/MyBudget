"""Rattachement du libellé à son article, décidé par le modèle de lien.

Les règles cherchent le libellé d'un article sur sa propre ligne, et à défaut
sur la dernière ligne sans prix rencontrée. Quand le prix est imprimé sur sa
propre ligne — pesée, quantité, code-barres — elles ramassent ce qui traînait
autour : « 0,792 kg 2,65 €/kg » au lieu de « POIRE CONFERENCE ». Mesuré sur
T1-test : la première cause d'article faux à montants justes.

**La décision revient au modèle, pas à un réglage.** La version précédente
demandait au tagger de rôles si la ligne du dessus était un `item_label`, puis
tranchait avec deux nombres choisis à la main : un recul d'une ligne, un seuil
de confiance. Or la distance dépend du ticket — chez une enseigne le prix est
sur la ligne du nom, chez une autre il vient après une ligne de pesée — et le
corpus annote déjà la réponse. La question posée ici est « à quelle distance
au-dessus est le libellé de cet article ? », et `train_link` l'apprend.

Le modèle désigne donc seul la ligne ; les règles gardent la main quand il
répond « sur la ligne du prix ».
"""

from __future__ import annotations

import joblib
import numpy as np

from line_classifier.train_link import LINK_MODEL_PATH
from reference.line_features_all import featurize, window
from reference.lines import PhysicalLine
from reference.structure import ExtractedItem, _clean_name, _plausible_label

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
) -> list[ExtractedItem]:
    """Donne à chaque article le libellé de la ligne que le modèle désigne.

    Les lignes désignées sont consommées dans l'ordre des articles, chacune
    une seule fois : deux articles ne partagent pas un nom."""
    if not len(offsets):
        return items
    used: set[int] = set()
    for item in items:
        if item.line_index is None or item.line_index >= len(offsets):
            continue
        candidate = item.line_index - int(offsets[item.line_index])
        if candidate == item.line_index or candidate < 0 or candidate in used:
            continue
        label = _plausible_label(lines[candidate].text)
        if label is None:
            continue
        item.name = _clean_name(label)
        used.add(candidate)
    return items
