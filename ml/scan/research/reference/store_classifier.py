"""L'enseigne, lue sur le ticket entier.

Le tagger désigne une ligne d'enseigne. Sur dix-sept tickets du held-out, il
n'y en a aucune à désigner : le logo n'est pas lu, et le nom n'est que dans
`www.auchan.fr`, dans « l'application CARREFOUR », dans un pied de ticket. Un
tagger de lignes ne peut pas apprendre ça, quelle que soit la quantité de
données : la question n'est pas « quelle ligne » mais « quel ticket ».

Ce classifieur pose cette question-là. Un ticket est un sac de mots et de
bigrammes hachés ; l'enseigne est une classe parmi celles que le corpus
d'entraînement connaît assez, ou « autre » — et « autre » rend la main à la
ligne désignée par le tagger. Régression logistique, poids élagués pour tenir
dans un asset ; l'inférence est une somme de poids, la même en Dart
(`pipeline/lib/src/store_classifier.dart`).

Aucun seuil de confiance : la classe « autre » est apprise comme les autres.
"""

from __future__ import annotations

import json
import zlib
from itertools import pairwise

from paths import MODELS_DIR
from reference.lines import PhysicalLine
from reference.store_gazetteer import normalize

STORE_CLASSIFIER_PATH = MODELS_DIR / "store_classifier.json"
BUCKETS = 1 << 16
OTHER = ""
# Quatre décimales suffisent à l'argmax et divisent l'asset par deux.
WEIGHT_DECIMALS = 4


def _bucket(token: str) -> int:
    return zlib.crc32(token.encode()) % BUCKETS


def ticket_features(lines: list[PhysicalLine]) -> set[int]:
    """Les mots et bigrammes normalisés du ticket, hachés. Un bigramme ne
    traverse pas une ligne : « AUCHAN » en fin de ligne et « PESSAC » au
    début de la suivante ne forment pas une expression."""
    features: set[int] = set()
    for line in lines:
        words = normalize(line.text).split()
        features.update(_bucket(word) for word in words)
        features.update(
            _bucket(f"{first} {second}") for first, second in pairwise(words)
        )
    return features


class StoreClassifier:
    """`classes[i]` est la graphie rendue ; `weights[i]` les poids non nuls de
    la classe, par trait haché ; la classe `OTHER` rend `None`."""

    def __init__(
        self,
        classes: list[str],
        intercepts: list[float],
        weights: list[dict[int, float]],
    ) -> None:
        if not len(classes) == len(intercepts) == len(weights):
            raise ValueError("classes, biais et poids doivent avoir la même longueur")
        self.classes = classes
        self.intercepts = intercepts
        self.weights = weights

    def scores(self, lines: list[PhysicalLine]) -> list[float]:
        features = ticket_features(lines)
        return [
            intercept + sum(weight.get(feature, 0.0) for feature in features)
            for intercept, weight in zip(self.intercepts, self.weights)
        ]

    def predict(self, lines: list[PhysicalLine]) -> str | None:
        scores = self.scores(lines)
        best = max(range(len(scores)), key=lambda index: scores[index])
        return self.classes[best] or None

    def to_json(self) -> dict:
        return {
            "buckets": BUCKETS,
            "classes": self.classes,
            "intercepts": [round(value, WEIGHT_DECIMALS) for value in self.intercepts],
            "weights": [
                {
                    str(feature): round(value, WEIGHT_DECIMALS)
                    for feature, value in sorted(weight.items())
                }
                for weight in self.weights
            ],
        }

    @classmethod
    def from_json(cls, data: dict) -> StoreClassifier:
        if data["buckets"] != BUCKETS:
            raise ValueError(
                f"{data['buckets']} seaux dans le modèle, {BUCKETS} attendus"
            )
        return cls(
            classes=list(data["classes"]),
            intercepts=[float(value) for value in data["intercepts"]],
            weights=[
                {int(feature): float(value) for feature, value in weight.items()}
                for weight in data["weights"]
            ],
        )


_classifier: StoreClassifier | None = None


def load() -> StoreClassifier:
    global _classifier
    if _classifier is None:
        _classifier = StoreClassifier.from_json(
            json.loads(STORE_CLASSIFIER_PATH.read_text())
        )
    return _classifier
