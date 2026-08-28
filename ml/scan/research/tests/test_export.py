"""L'export JSON rend exactement ce que rend sklearn."""

from __future__ import annotations

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier

from line_classifier.export import export, predict_proba_exported

MAX_DRIFT = 1e-12


def _trained(classes: int) -> tuple[HistGradientBoostingClassifier, np.ndarray]:
    generator = np.random.default_rng(0)
    features = generator.normal(size=(400, 5))
    targets = (features[:, 0] * 2 + features[:, 1]).argsort() % classes
    model = HistGradientBoostingClassifier(max_iter=20, random_state=0)
    model.fit(features, targets)
    return model, features[:40]


def _worst_drift(classes: int) -> float:
    model, sample = _trained(classes)
    exported = export(model, [f"f{index}" for index in range(sample.shape[1])])
    return max(
        max(
            abs(left - right)
            for left, right in zip(
                predict_proba_exported(exported, list(row)), reference
            )
        )
        for row, reference in zip(sample, model.predict_proba(sample))
    )


def test_un_modele_binaire_se_lit_a_la_sigmoide() -> None:
    """Une seule sortie brute : le softmax rendrait 1,0 pour tout le monde."""
    assert _worst_drift(2) < MAX_DRIFT


def test_un_modele_multiclasse_se_lit_au_softmax() -> None:
    assert _worst_drift(4) < MAX_DRIFT
