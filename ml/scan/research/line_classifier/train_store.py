"""Entraîne le classifieur d'enseigne : quel ticket est-ce ?

Le tagger désigne une ligne d'enseigne, et sur les tickets où le nom n'est
qu'un domaine web ou un pied de ticket, il n'a rien à désigner. Ce modèle lit
le ticket entier — mots et bigrammes hachés de toutes ses lignes — et rend
l'enseigne parmi celles que le corpus d'entraînement connaît assez, ou
« autre ». Régression logistique multinomiale ; les poids sont élagués aux
plus forts de chaque classe pour tenir dans un asset, et c'est le modèle
élagué qui est mesuré.

Les trois constantes (support minimal d'une classe, régularisation, élagage)
viennent d'une validation croisée par ticket sur l'entraînement seul ; le
held-out ne sert qu'à constater.

    uv run python -m line_classifier.train_store
"""

from __future__ import annotations

import json
from collections import Counter

import numpy as np
from scipy.sparse import csr_matrix
from sklearn.linear_model import LogisticRegression

from annotate.dataset import AnnotatedReceipt, load
from bench.exactness import store_matches
from reference.header_ml import role_probabilities, store_of
from reference.store_classifier import (
    BUCKETS,
    OTHER,
    STORE_CLASSIFIER_PATH,
    StoreClassifier,
    ticket_features,
)
from reference.store_gazetteer import normalize

MIN_CLASS_SUPPORT = 5
REGULARIZATION = 10.0
WEIGHTS_PER_CLASS = 3000
MAX_ITERATIONS = 3000
EVALUATION_CORPUS = "open_prices"


def _matrix(receipts: list[AnnotatedReceipt]) -> csr_matrix:
    rows, columns = [], []
    for row, receipt in enumerate(receipts):
        for column in ticket_features(receipt.lines):
            rows.append(row)
            columns.append(column)
    return csr_matrix(
        (np.ones(len(rows)), (rows, columns)), shape=(len(receipts), BUCKETS)
    )


def _labels(receipts: list[AnnotatedReceipt]) -> tuple[list[str], dict[str, str]]:
    """La clé de chaque ticket — « autre » sous le support — et la graphie la
    plus fréquente de chaque clé."""
    counts = Counter(normalize(receipt.store) for receipt in receipts)
    spellings: dict[str, Counter[str]] = {}
    for receipt in receipts:
        spellings.setdefault(normalize(receipt.store), Counter())[
            receipt.store.strip()
        ] += 1
    labels = [
        key if counts[key] >= MIN_CLASS_SUPPORT else OTHER
        for key in (normalize(receipt.store) for receipt in receipts)
    ]
    return labels, {key: c.most_common(1)[0][0] for key, c in spellings.items()}


def _pruned(coefficients: np.ndarray) -> list[dict[int, float]]:
    weights = []
    for row in coefficients:
        keep = np.argsort(-np.abs(row))[:WEIGHTS_PER_CLASS]
        weights.append({int(i): float(row[i]) for i in keep if row[i] != 0.0})
    return weights


def train(receipts: list[AnnotatedReceipt]) -> StoreClassifier:
    labels, spellings = _labels(receipts)
    model = LogisticRegression(C=REGULARIZATION, max_iter=MAX_ITERATIONS)
    model.fit(_matrix(receipts), labels)
    return StoreClassifier(
        classes=[
            spellings.get(key, key) if key != OTHER else OTHER for key in model.classes_
        ],
        intercepts=[float(value) for value in model.intercept_],
        weights=_pruned(model.coef_),
    )


def evaluate(classifier: StoreClassifier, receipts: list[AnnotatedReceipt]) -> None:
    designated = classified = spoke = 0
    for receipt in receipts:
        probabilities = role_probabilities(receipt.lines)
        line_only = store_of(
            receipt.lines,
            probabilities,
            classifier=StoreClassifier([OTHER], [0.0], [{}]),
        )
        with_ticket = store_of(receipt.lines, probabilities, classifier=classifier)
        designated += store_matches(line_only, receipt.store)
        classified += store_matches(with_ticket, receipt.store)
        spoke += classifier.predict(receipt.lines) is not None
    print(
        f"évaluation : {len(receipts)} tickets à enseigne connue ({EVALUATION_CORPUS}, held-out)"
    )
    print(f"  ligne désignée seule : {designated} justes")
    print(
        f"  ticket puis ligne    : {classified} justes (le classifieur parle sur {spoke})"
    )


def main() -> None:
    training = [receipt for receipt in load(held_out=False) if receipt.store]
    evaluation = [
        receipt
        for receipt in load(held_out=True)
        if receipt.corpus == EVALUATION_CORPUS and receipt.store
    ]
    classifier = train(training)
    real_classes = sum(1 for name in classifier.classes if name != OTHER)
    weights = sum(len(weight) for weight in classifier.weights)
    print(
        f"entraînement : {len(training)} tickets, {real_classes} enseignes, {weights} poids"
    )
    evaluate(classifier, evaluation)
    STORE_CLASSIFIER_PATH.parent.mkdir(parents=True, exist_ok=True)
    STORE_CLASSIFIER_PATH.write_text(
        json.dumps(classifier.to_json(), ensure_ascii=False)
    )
    print(f"modèle écrit : {STORE_CLASSIFIER_PATH}")


if __name__ == "__main__":
    main()
