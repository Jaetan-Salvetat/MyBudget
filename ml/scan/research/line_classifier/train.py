"""Entraîne le classifieur de lignes sur le corpus annoté.

Ce qui change par rapport à la version précédente : la vérité. Elle prenait
les décisions des règles (`extract()`) pour référence sur les 77 % de tickets
qu'elles validaient — le modèle était leur élève et ne pouvait pas les
dépasser. Elle vient maintenant d'annotations produites depuis l'image et
filtrées par checksum (`annotate/README.md`), vérifiées à 99,5 % / 100 %
contre le golden FindIt.

Le jeu d'évaluation (`T1-test`, `photos_pixel`) ne sert jamais à entraîner.

    uv run python -m line_classifier.train
"""

from __future__ import annotations

import joblib
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import classification_report, log_loss

from annotate.dataset import load
from line_classifier.dataset import labelled_lines
from reference.line_features_v3 import featurize
from reference.line_labels import CLASS_NAMES
from reference.structure_ml import MODEL_PATH

SATURATION_THRESHOLD = 0.99


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


def _report_calibration(model, x_test, y_test) -> None:
    """Le décodeur sous contrainte consomme des probabilités, pas un argmax :
    un modèle sûr de lui et faux lui coûte plus cher qu'un modèle hésitant."""
    probabilities = model.predict_proba(x_test)
    print(f"log-loss test : {log_loss(y_test, probabilities):.4f}")
    confident = probabilities.max(axis=1) >= SATURATION_THRESHOLD
    wrong = (model.predict(x_test) != y_test) & confident
    print(
        f"lignes à P≥{SATURATION_THRESHOLD} : {confident.mean():.1%}, "
        f"dont fausses : {wrong.sum()}"
    )


def main() -> None:
    train_receipts = load()
    test_receipts = load(held_out=True)
    x_train, y_train = labelled_lines(train_receipts, featurize)
    x_test, y_test = labelled_lines(test_receipts, featurize)
    print(f"entraînement : {len(train_receipts)} tickets, {len(y_train)} lignes")
    print(f"évaluation   : {len(test_receipts)} tickets, {len(y_test)} lignes")

    # Pas de rééquilibrage de classes : mesuré, il remonte le rappel de
    # `discount` mais rend le modèle plus affirmatif partout, et le décodeur
    # sous contrainte trouve alors des combinaisons fausses qui passent le
    # checksum — les faux vérifiés doublent sur T1-test. La barre du flow est
    # zéro montant faux, elle prime sur le rappel d'une classe rare.
    model = _model()
    model.fit(x_train, y_train)

    print(
        classification_report(
            y_test, model.predict(x_test), target_names=CLASS_NAMES, digits=3
        )
    )
    _report_calibration(model, x_test, y_test)

    MODEL_PATH.parent.mkdir(exist_ok=True)
    joblib.dump(model, MODEL_PATH)
    print(f"modèle → {MODEL_PATH}")


if __name__ == "__main__":
    main()
