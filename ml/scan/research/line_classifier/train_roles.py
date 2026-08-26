"""Entraîne le tagger de rôles : toutes les lignes, 9 classes.

Le classifieur historique (`train.py`) n'étiquette que les lignes porteuses
de prix, en 5 classes : il ne peut désigner ni l'enseigne, ni la ligne de
date, ni le libellé d'un article dont le prix est imprimé plus bas — les
trois postes d'erreur les plus coûteux de la métrique produit.

Un seul modèle, pas un par champ : les rôles de ligne sont mutuellement
exclusifs, les séparer fabriquerait des conflits à arbitrer, et le corpus ne
nourrirait pas plusieurs modèles.

Le corpus annote 14 rôles, le modèle en prédit 9 : six d'entre eux ne sont
lus par aucun consommateur, et les distinguer coûtait 41 % des erreurs du
tagger sans rien rapporter. La projection est dans `line_labels.py`.

L'entraînement prend aussi les tickets écartés pour un montant illisible :
le checksum protège les montants, pas l'étiquetage des lignes, et leurs rôles
restent exploitables. Mesuré, ils valent plus que le bruit qu'ils apportent
(F1 d'`item_label` 0,801 → 0,825). Le jeu d'évaluation, lui, reste strict.

    uv run python -m line_classifier.train_roles
"""

from __future__ import annotations

import joblib
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import classification_report

from annotate.dataset import AnnotatedReceipt, load
from paths import ROLE_MODEL_PATH
from reference.line_features_all import featurize
from reference.line_labels import TAGGER_ROLES, tagger_role

ROLE_INDEX = {role: index for index, role in enumerate(TAGGER_ROLES)}


def dataset(receipts: list[AnnotatedReceipt]) -> tuple[np.ndarray, np.ndarray]:
    features: list[list[float]] = []
    labels: list[int] = []
    for receipt in receipts:
        rows = featurize(receipt.lines)
        if len(rows) != len(receipt.roles):
            continue
        features.extend(rows)
        labels.extend(ROLE_INDEX[tagger_role(role)] for role in receipt.roles)
    return np.array(features), np.array(labels)


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
    train_receipts, test_receipts = load(roles_only=True), load(held_out=True)
    x_train, y_train = dataset(train_receipts)
    x_test, y_test = dataset(test_receipts)
    print(f"entraînement : {len(train_receipts)} tickets, {len(y_train)} lignes")
    print(f"évaluation   : {len(test_receipts)} tickets, {len(y_test)} lignes")

    model = _model()
    model.fit(x_train, y_train)
    present = sorted(set(y_test) | set(model.predict(x_test)))
    print(
        classification_report(
            y_test,
            model.predict(x_test),
            labels=present,
            target_names=[TAGGER_ROLES[i] for i in present],
            digits=3,
            zero_division=0,
        )
    )
    ROLE_MODEL_PATH.parent.mkdir(exist_ok=True)
    joblib.dump(model, ROLE_MODEL_PATH)
    print(f"modèle → {ROLE_MODEL_PATH}")


if __name__ == "__main__":
    main()
