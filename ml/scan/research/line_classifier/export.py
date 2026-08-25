"""Exporte le classifieur de lignes (HistGradientBoosting) en JSON portable.

Format : baseline par classe + liste d'itérations, chaque itération = un
arbre par classe, chaque arbre = tableau de nœuds (feature, seuil, gauche,
droite, valeur, sens des valeurs manquantes). Inférence pure Dart dans
`pipeline/lib/src/classifier.dart` : score brut = baseline + Σ feuilles,
softmax. `predict_proba_exported` est la référence Python du même calcul,
vérifiée égale à sklearn.
"""

from __future__ import annotations

import json
import math
import sys

import numpy as np

from paths import APP_MODELS_DIR, MODELS_DIR
from reference.line_features_v3 import FEATURE_NAMES_V3
from reference.structure_ml import MODEL_PATHS, load_classifier

EXPORT_PATH = MODELS_DIR / "line_clf_v3.json"
APP_ASSET_PATH = APP_MODELS_DIR / "line_clf_v3.json"


def export(model) -> dict:
    iterations = []
    for predictors in model._predictors:
        trees = []
        for tree in predictors:
            nodes = tree.nodes
            trees.append(
                [
                    [
                        int(node["feature_idx"]),
                        float(node["num_threshold"]),
                        int(node["left"]),
                        int(node["right"]),
                        float(node["value"]),
                        int(node["missing_go_to_left"]),
                        int(node["is_leaf"]),
                    ]
                    for node in nodes
                ]
            )
        iterations.append(trees)
    return {
        "version": "v3",
        "classes": [int(c) for c in model.classes_],
        "featureNames": FEATURE_NAMES_V3,
        "baseline": [float(v) for v in np.ravel(model._baseline_prediction)],
        "iterations": iterations,
    }


def _tree_value(nodes: list[list[float]], row: list[float]) -> float:
    index = 0
    while True:
        feature, threshold, left, right, value, missing_left, is_leaf = nodes[index]
        if is_leaf:
            return value
        x = row[int(feature)]
        if math.isnan(x):
            index = left if missing_left else right
        else:
            index = left if x <= threshold else right


def predict_proba_exported(exported: dict, row: list[float]) -> list[float]:
    raw = list(exported["baseline"])
    for trees in exported["iterations"]:
        for class_index, nodes in enumerate(trees):
            raw[class_index] += _tree_value(nodes, row)
    peak = max(raw)
    weights = [math.exp(v - peak) for v in raw]
    total = sum(weights)
    return [w / total for w in weights]


def main() -> None:
    model, _ = load_classifier("v3")
    exported = export(model)
    payload = json.dumps(exported, separators=(",", ":"))
    EXPORT_PATH.write_text(payload)
    # L'app lit ce même artefact : deux copies qui divergeraient feraient
    # décider le device autrement que la référence Python.
    APP_ASSET_PATH.write_text(payload)
    size = EXPORT_PATH.stat().st_size / 1e6
    print(f"{MODEL_PATHS['v3'].name} → {EXPORT_PATH} et {APP_ASSET_PATH} ({size:.1f} MB)")
    if "--check" in sys.argv:
        from line_classifier.train import build_dataset

        x_test, _ = build_dataset("t1test", load_classifier("v3")[1])
        reference = model.predict_proba(x_test)
        worst = max(
            max(
                abs(a - b)
                for a, b in zip(predict_proba_exported(exported, list(row)), ref)
            )
            for row, ref in zip(x_test, reference)
        )
        print(f"écart max export vs sklearn sur t1test : {worst:.2e}")


if __name__ == "__main__":
    main()
