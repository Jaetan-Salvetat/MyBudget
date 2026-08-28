"""Exporte le modèle de lien en JSON portable, pour l'inférence Dart.

Même format que les deux autres modèles (`export.py`) : l'inférence Dart est
générique sur le nombre de classes et de colonnes. Ce modèle-ci lit une
fenêtre — la ligne et les trois qui la précèdent — d'où un vecteur quatre
fois plus long ; les noms de colonnes exportés portent leur recul, et le Dart
les vérifie au chargement.

    uv run python -m line_classifier.export_link [--check]
"""

from __future__ import annotations

import json
import sys

import joblib

from annotate.dataset import load
from line_classifier.export import export, predict_proba_exported
from line_classifier.train_link import dataset
from paths import LINK_MODEL_PATH, MODELS_DIR
from reference.line_features_all import window_feature_names

EXPORT_PATH = MODELS_DIR / "label_link.json"
MAX_ACCEPTABLE_DRIFT = 1e-9


def main() -> int:
    model = joblib.load(LINK_MODEL_PATH)
    exported = export(model, window_feature_names(), version="link-v1")
    EXPORT_PATH.write_text(json.dumps(exported, separators=(",", ":")))
    size = EXPORT_PATH.stat().st_size / 1e6
    print(f"{LINK_MODEL_PATH.name} → {EXPORT_PATH} ({size:.1f} MB)")

    if "--check" in sys.argv:
        x_test, _ = dataset(load(held_out=True))
        reference = model.predict_proba(x_test)
        worst = max(
            max(
                abs(a - b)
                for a, b in zip(predict_proba_exported(exported, list(row)), ref)
            )
            for row, ref in zip(x_test, reference)
        )
        print(f"écart max export vs sklearn : {worst:.2e}")
        if worst > MAX_ACCEPTABLE_DRIFT:
            print("ÉCART INACCEPTABLE", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
