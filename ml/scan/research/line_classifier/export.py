"""Exporte un HistGradientBoosting en JSON portable.

Format : baseline par sortie + liste d'itérations, chaque itération = un
arbre par sortie, chaque arbre = tableau de nœuds (feature, seuil, gauche,
droite, valeur, sens des valeurs manquantes). Inférence pure Dart dans
`pipeline/lib/src/classifier.dart` : score brut = baseline + Σ feuilles, puis
softmax — ou sigmoïde quand le modèle est binaire et n'a qu'une sortie.
`predict_proba_exported` est la référence Python du même calcul, vérifiée
égale à sklearn.
"""

from __future__ import annotations

import math

import numpy as np


def export(model, feature_names: list[str], version: str = "v3") -> dict:
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
        "version": version,
        "classes": [int(c) for c in model.classes_],
        "featureNames": feature_names,
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
    """Référence Python de l'inférence Dart, égale à sklearn.

    Un modèle binaire n'a qu'une sortie brute et se lit à la sigmoïde ; au-delà
    de deux classes, une sortie par classe et un softmax. C'est la convention
    de sklearn, et le Dart applique la même règle."""
    raw = list(exported["baseline"])
    for trees in exported["iterations"]:
        for class_index, nodes in enumerate(trees):
            raw[class_index] += _tree_value(nodes, row)
    if len(raw) == 1:
        probability = 1 / (1 + math.exp(-raw[0]))
        return [1 - probability, probability]
    peak = max(raw)
    weights = [math.exp(v - peak) for v in raw]
    total = sum(weights)
    return [w / total for w in weights]
