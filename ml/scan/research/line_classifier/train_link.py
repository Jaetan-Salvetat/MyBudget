"""Entraîne le modèle de lien : où est le libellé de cet article ?

Le rattachement était une règle de distance — la ligne juste au-dessus, si le
tagger la désignait avec assez de confiance. Deux réglages arbitraires (le
recul, le seuil) pour une question qui dépend du ticket : chez une enseigne le
prix est sur la ligne du nom, chez une autre il est deux lignes plus bas après
une pesée. Le corpus annote déjà la réponse (`label_index`), et c'est donc une
question apprise comme les autres.

Le modèle répond par une distance : 0 quand le libellé est sur la ligne du
prix, k quand il est k lignes au-dessus.

    uv run python -m line_classifier.train_link
"""

from __future__ import annotations

import joblib
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import classification_report

from annotate.dataset import AnnotatedReceipt, load
from annotate.schema import ITEM
from paths import LINK_MODEL_PATH, MODELS_DIR
from reference.line_features_all import featurize, window

# Mesuré sur le corpus : 96 % des libellés déportés sont une ligne au-dessus
# de leur prix, le reste à deux ou trois. Au-delà, la vérité annotée est trop
# rare pour être apprise, et un rattachement lointain rapporte moins de bons
# libellés qu'il n'en écrase.
MAX_OFFSET = 3


def dataset(receipts: list[AnnotatedReceipt]) -> tuple[np.ndarray, np.ndarray]:
    features: list[list[float]] = []
    offsets: list[int] = []
    for receipt in receipts:
        rows = featurize(receipt.lines)
        if len(rows) != len(receipt.roles):
            continue
        for index, role in enumerate(receipt.roles):
            if role != ITEM:
                continue
            target = receipt.label_indexes[index]
            distance = 0 if target is None else min(MAX_OFFSET, max(0, index - target))
            features.append(window(rows, index))
            offsets.append(distance)
    return np.array(features), np.array(offsets)


def _model() -> HistGradientBoostingClassifier:
    return HistGradientBoostingClassifier(
        max_iter=600,
        learning_rate=0.05,
        min_samples_leaf=20,
        l2_regularization=1.0,
        early_stopping=True,
        validation_fraction=0.15,
        n_iter_no_change=30,
        random_state=42,
    )


def main() -> None:
    x_train, y_train = dataset(load())
    x_test, y_test = dataset(load(held_out=True))
    print(f"entraînement : {len(y_train)} lignes d'article")
    print(f"évaluation   : {len(y_test)} lignes d'article")

    model = _model()
    model.fit(x_train, y_train)
    predicted = model.predict(x_test)
    baseline = (y_test == 0).mean()
    print(f"\nexactitude {(predicted == y_test).mean():.1%} (libellé toujours sur la ligne du prix : {baseline:.1%})")
    print(classification_report(y_test, predicted, digits=3, zero_division=0))

    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, LINK_MODEL_PATH)
    print(f"modèle écrit : {LINK_MODEL_PATH}")


if __name__ == "__main__":
    main()
