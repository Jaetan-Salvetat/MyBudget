"""Exporte le tagger de spans en JSON portable, pour l'inférence Dart.

Même format que les autres modèles (`export.py`) : l'inférence Dart est
générique sur le nombre de classes et de colonnes. Celui-ci décrit un mot et
non une ligne — ses colonnes sont celles de `word_features`.

    uv run python -m line_classifier.export_span [--check]
"""

from __future__ import annotations

import json
import sys

import joblib

from line_classifier.export import export, predict_proba_exported
from line_classifier.train_span import dataset, held_out
from paths import MODELS_DIR, SPAN_MODEL_PATH
from reference.word_features import FEATURE_NAMES

EXPORT_PATH = MODELS_DIR / "label_span.json"
MAX_ACCEPTABLE_DRIFT = 1e-9


def main() -> int:
    model = joblib.load(SPAN_MODEL_PATH)
    exported = export(model, FEATURE_NAMES, version="span-v1")
    EXPORT_PATH.write_text(json.dumps(exported, separators=(",", ":")))
    size = EXPORT_PATH.stat().st_size / 1e6
    print(f"{SPAN_MODEL_PATH.name} → {EXPORT_PATH} ({size:.1f} MB)")

    if "--check" in sys.argv:
        x_test, _ = dataset(held_out())
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
