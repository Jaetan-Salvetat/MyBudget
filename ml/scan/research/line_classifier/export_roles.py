"""Exporte le tagger de rôles en JSON portable, pour l'inférence Dart.

Même format que le classifieur de lignes (`export.py`) : l'inférence Dart de
`pipeline/lib/src/classifier.dart` est générique sur le nombre de classes,
elle lit les quatorze rôles sans rien savoir de plus.

    uv run python -m line_classifier.export_roles [--check]
"""

from __future__ import annotations

import json
import sys

import joblib

from annotate.dataset import load
from annotate.schema import ROLES
from line_classifier.export import export, predict_proba_exported
from line_classifier.train_roles import ROLE_MODEL_PATH, dataset
from paths import MODELS_DIR
from reference.line_features_all import FEATURE_NAMES

EXPORT_PATH = MODELS_DIR / "line_roles.json"
MAX_ACCEPTABLE_DRIFT = 1e-9


def main() -> int:
    model = joblib.load(ROLE_MODEL_PATH)
    exported = export(model, FEATURE_NAMES, version="roles-v1")
    exported["roles"] = list(ROLES)
    EXPORT_PATH.write_text(json.dumps(exported, separators=(",", ":")))
    size = EXPORT_PATH.stat().st_size / 1e6
    print(f"{ROLE_MODEL_PATH.name} → {EXPORT_PATH} ({size:.1f} MB)")

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
