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

import json
from pathlib import Path

import joblib
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import classification_report

from analyze_local_failures import golden_checksummable
from line_features import featurize, merged_lines
from lines import cluster_lines, deskew_words, load_words, median_angle
from score_device_flow import load_tickets
from structure import PAYMENT_WORDS, _contains, extract

ROOT = Path(__file__).parent.parent
MODEL_PATH = Path(__file__).parent / "models" / "line_clf.joblib"

ITEM, DISCOUNT, TOTAL, PAYMENT, IGNORE = 0, 1, 2, 3, 4
CLASS_NAMES = ["item", "discount", "total", "payment", "ignore"]
EPSILON = 0.005


ROLE_TO_CLASS = {
    "item": ITEM,
    "discount": DISCOUNT,
    "total": TOTAL,
    "subtotal": TOTAL,
    "payment": PAYMENT,
}


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
        return [
            ROLE_TO_CLASS.get(roles.get(priced.index), IGNORE)
            for priced in lines
        ]

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
        elif price >= 0 and abs(price - total) < EPSILON and (
            _contains(text, PAYMENT_WORDS)
        ):
            labels.append(PAYMENT)
        elif price >= 0 and _consume(remaining_items, price):
            labels.append(ITEM)
        else:
            labels.append(None)
    return labels


def _consume(values: list[float], target: float) -> bool:
    for index, value in enumerate(values):
        if abs(value - target) < EPSILON:
            values.pop(index)
            return True
    return False


def build_dataset(split: str):
    features = []
    labels = []
    tickets = 0
    for ticket in load_tickets(ROOT / "results" / "device_flow"):
        if ticket.split != split:
            continue
        words, data = load_words(ticket.dump_path)
        merged = merged_lines(
            cluster_lines(deskew_words(words, median_angle(data)))
        )
        lines, rows = featurize(merged)
        if not lines:
            continue
        raw = cluster_lines(deskew_words(words, median_angle(data)))
        ticket_labels = _labels_for(ticket, raw, lines)
        if ticket_labels is None:
            continue
        kept = [
            (row, label)
            for row, label in zip(rows, ticket_labels)
            if label is not None
        ]
        if not kept:
            continue
        features.extend(row for row, _ in kept)
        labels.extend(label for _, label in kept)
        tickets += 1
    print(f"{split}: {tickets} tickets, {len(labels)} lignes")
    return np.array(features), np.array(labels)


def main() -> None:
    x_train, y_train = build_dataset("t1train")
    x_test, y_test = build_dataset("t1test")

    model = HistGradientBoostingClassifier(
        max_iter=300, learning_rate=0.1, random_state=42
    )
    model.fit(x_train, y_train)

    predictions = model.predict(x_test)
    print(
        classification_report(
            y_test, predictions, target_names=CLASS_NAMES, digits=3
        )
    )
    MODEL_PATH.parent.mkdir(exist_ok=True)
    joblib.dump(model, MODEL_PATH)
    print(f"modèle → {MODEL_PATH}")


if __name__ == "__main__":
    main()
