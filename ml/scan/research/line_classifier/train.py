"""Entraîne le classifieur de lignes V2 (lignes porteuses de prix).

Étiquetage automatique en deux régimes : sur un ticket que les règles
valident (checksum OK), les rôles réellement joués sont la vérité ; sur un
ticket échoué, seules les lignes dont le montant matche le golden sans
ambiguïté reçoivent un label correctif, les autres sont EXCLUES — étiqueter
« ignore » une ligne d'article au montant abîmé par l'OCR apprendrait au
modèle à jeter des articles, alors que c'est le rôle du checksum.

Découpage : entraînement sur T1-train, évaluation sur T1-test.
"""

from __future__ import annotations

import sys

import joblib
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import classification_report, log_loss

from bench.device_flow import load_tickets
from bench.failures import golden_checksummable
from paths import RESULTS_DIR
from reference.line_features import merged_lines
from reference.line_features_v3 import fuzzy_lexicon_similarity
from reference.line_labels import (
    CLASS_NAMES,
    DISCOUNT,
    IGNORE,
    ITEM,
    PAYMENT,
    ROLE_TO_CLASS,
    TOTAL,
)
from reference.lines import cluster_lines, deskew_words, load_words, median_angle
from reference.structure import PAYMENT_WORDS, TOTAL_WORDS, _contains, extract
from reference.structure_ml import FEATURIZERS, MODEL_PATHS

SATURATION_THRESHOLD = 0.99
FUZZY_ROLE_THRESHOLD = 0.6

EPSILON = 0.005




def _labels_for(ticket, raw_lines, lines) -> list[int | None] | None:
    """Labels par ligne porteuse de prix, ou None pour « ligne incertaine,
    exclue de l'entraînement ».

    Ticket validé par les règles : les rôles joués sont la vérité (le
    checksum les a confirmés). Ticket échoué : seules les lignes dont le
    montant matche le golden sans ambiguïté reçoivent un label correctif —
    étiqueter « ignore » une ligne d'article dont l'OCR a abîmé le montant
    apprendrait au modèle à jeter des articles."""
    roles: dict[int, str] = {}
    receipt = extract(raw_lines, roles=roles)
    if receipt.checksum_ok:
        return [ROLE_TO_CLASS.get(roles.get(priced.index), IGNORE) for priced in lines]

    golden = ticket.golden["receipt"]
    if not golden_checksummable(ticket.golden):
        return None
    remaining_items = [
        round(float(i["amount"]), 2)
        for i in golden["items"]
        if abs(i["amount"]) >= EPSILON
    ]
    remaining_discounts = [
        round(abs(float(i.get("discount") or 0)), 2)
        for i in golden["items"]
        if abs(i.get("discount") or 0) >= EPSILON
    ]
    total = round(float(golden["total"]), 2)

    labels: list[int | None] = []
    for priced in lines:
        price = round(priced.price, 2)
        text = priced.line.text
        if price < 0 and _consume(remaining_discounts, -price):
            labels.append(DISCOUNT)
        elif (
            price >= 0
            and abs(price - total) < EPSILON
            and (_contains(text, PAYMENT_WORDS))
        ):
            labels.append(PAYMENT)
        elif price >= 0 and _consume(remaining_items, price):
            labels.append(ITEM)
        elif price >= 0 and abs(price - total) < EPSILON:
            labels.append(_reference_role(text))
        else:
            labels.append(None)
    return labels


def _reference_role(text: str) -> int | None:
    """Ligne au montant du total golden, non consommée comme article : total
    ou paiement selon son libellé (lexique flou, l'OCR abîme ces mots), sinon
    incertaine — « rendu », « versé » portent parfois la même valeur."""
    if fuzzy_lexicon_similarity(text, TOTAL_WORDS) >= FUZZY_ROLE_THRESHOLD:
        return TOTAL
    if fuzzy_lexicon_similarity(text, PAYMENT_WORDS) >= FUZZY_ROLE_THRESHOLD:
        return PAYMENT
    return None


def _consume(values: list[float], target: float) -> bool:
    for index, value in enumerate(values):
        if abs(value - target) < EPSILON:
            values.pop(index)
            return True
    return False


def build_dataset(split: str, featurize):
    features = []
    labels = []
    tickets = 0
    for ticket in load_tickets(RESULTS_DIR / "device_flow"):
        if ticket.split != split:
            continue
        words, data = load_words(ticket.dump_path)
        merged = merged_lines(cluster_lines(deskew_words(words, median_angle(data))))
        lines, rows = featurize(merged)
        if not lines:
            continue
        raw = cluster_lines(deskew_words(words, median_angle(data)))
        ticket_labels = _labels_for(ticket, raw, lines)
        if ticket_labels is None:
            continue
        kept = [
            (row, label) for row, label in zip(rows, ticket_labels) if label is not None
        ]
        if not kept:
            continue
        features.extend(row for row, _ in kept)
        labels.extend(label for _, label in kept)
        tickets += 1
    print(f"{split}: {tickets} tickets, {len(labels)} lignes")
    return np.array(features), np.array(labels)


def _model_for(version: str) -> HistGradientBoostingClassifier:
    if version == "v2":
        return HistGradientBoostingClassifier(
            max_iter=300, learning_rate=0.1, random_state=42
        )
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
    probas = model.predict_proba(x_test)
    print(f"log-loss test : {log_loss(y_test, probas):.4f}")
    confident = probas.max(axis=1) >= SATURATION_THRESHOLD
    wrong_confident = (model.predict(x_test) != y_test) & confident
    print(
        f"lignes à P≥{SATURATION_THRESHOLD} : {confident.mean():.1%}, "
        f"dont fausses : {wrong_confident.sum()}"
    )


def main() -> None:
    version = "v3" if "--v3" in sys.argv else "v2"
    featurize = FEATURIZERS[version]
    x_train, y_train = build_dataset("t1train", featurize)
    x_test, y_test = build_dataset("t1test", featurize)

    model = _model_for(version)
    model.fit(x_train, y_train)

    predictions = model.predict(x_test)
    print(
        classification_report(y_test, predictions, target_names=CLASS_NAMES, digits=3)
    )
    _report_calibration(model, x_test, y_test)
    path = MODEL_PATHS[version]
    path.parent.mkdir(exist_ok=True)
    joblib.dump(model, path)
    print(f"modèle {version} → {path}")


if __name__ == "__main__":
    main()
