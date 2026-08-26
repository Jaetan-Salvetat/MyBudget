"""Compare les modèles Dart à la référence Python, ligne à ligne et mot à mot.

Le portage est spécifié par cette égalité : mêmes features à 1e-9 près, même
rôle prédit, même distance au libellé, même libellé découpé. Une colonne
décalée ne se voit pas autrement — le modèle continue de répondre, simplement
il répond autre chose que la référence.

    uv run python -m bench.roles_parity [<dossier d'annotations>...]
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import numpy as np

from annotate.revalidate import _lines_of
from annotate.run import ANNOTATIONS_DIR
from line_classifier.export_link import EXPORT_PATH as LINK_EXPORT_PATH
from line_classifier.export_roles import EXPORT_PATH
from line_classifier.export_span import EXPORT_PATH as SPAN_EXPORT_PATH
from paths import PIPELINE_DIR
from reference.header_ml import role_probabilities
from reference.labels_ml import label_offsets
from reference.line_features_all import featurize
from reference.spans_ml import label_of, label_probabilities
from reference.word_features import featurize as featurize_words

MAX_FEATURE_DRIFT = 1e-9
DEFAULT_CORPORA = ("photos_pixel", "selection_web", "mixed")


def _dart_output(directories: list[Path]) -> dict:
    command = [
        "dart",
        "tool/roles_parity.dart",
        f"--model={EXPORT_PATH}",
        f"--link={LINK_EXPORT_PATH}",
        f"--span={SPAN_EXPORT_PATH}",
        *[str(directory) for directory in directories],
    ]
    result = subprocess.run(
        command, cwd=PIPELINE_DIR, capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        raise SystemExit(f"tool/roles_parity.dart a échoué ({result.returncode})")
    return json.loads(result.stdout)


def main(argv: list[str]) -> int:
    directories = (
        [Path(a) for a in argv]
        if argv
        else [ANNOTATIONS_DIR / name for name in DEFAULT_CORPORA]
    )
    directories = [d for d in directories if d.is_dir()]
    dart = _dart_output(directories)

    tickets = 0
    feature_mismatches = 0
    role_mismatches = 0
    link_mismatches = 0
    word_mismatches = 0
    label_mismatches = 0
    worst_drift = 0.0
    worst_word_drift = 0.0
    for directory in directories:
        for path in sorted(directory.glob("*.json")):
            expected = dart.get(path.name)
            if expected is None:
                continue
            record = json.loads(path.read_text())
            lines = _lines_of(record)
            if not lines:
                continue
            tickets += 1
            rows = np.array(featurize(lines))
            dart_rows = np.array(expected["features"])
            if rows.shape != dart_rows.shape:
                feature_mismatches += 1
                print(f"FORME {path.name}: {rows.shape} vs {dart_rows.shape}")
                continue
            drift = float(np.max(np.abs(rows - dart_rows)))
            worst_drift = max(worst_drift, drift)
            if drift > MAX_FEATURE_DRIFT:
                feature_mismatches += 1
                column = int(np.unravel_index(np.argmax(np.abs(rows - dart_rows)), rows.shape)[1])
                print(f"FEATURES {path.name}: écart {drift:.2e} colonne {column}")

            python_roles = list(role_probabilities(lines).argmax(axis=1))
            if python_roles != expected["roles"]:
                role_mismatches += 1
                differing = [
                    i for i, (a, b) in enumerate(zip(python_roles, expected["roles"]))
                    if a != b
                ]
                print(f"RÔLES {path.name}: lignes {differing[:5]}")

            python_words = [
                value
                for row in featurize_words(lines)
                for value in row
            ]
            dart_words = [
                value for row in expected["wordFeatures"] for value in row
            ]
            if len(python_words) != len(dart_words):
                word_mismatches += 1
                print(
                    f"FORME MOTS {path.name}: {len(python_words)} "
                    f"vs {len(dart_words)}"
                )
            else:
                word_drift = max(
                    (
                        float(np.max(np.abs(np.array(a) - np.array(b))))
                        for a, b in zip(python_words, dart_words)
                    ),
                    default=0.0,
                )
                worst_word_drift = max(worst_word_drift, word_drift)
                if word_drift > MAX_FEATURE_DRIFT:
                    word_mismatches += 1
                    print(f"FEATURES MOTS {path.name}: écart {word_drift:.2e}")

            spans = label_probabilities(lines)
            python_labels = [
                label_of(line, spans[index]) for index, line in enumerate(lines)
            ]
            if python_labels != expected["labels"]:
                label_mismatches += 1
                differing = [
                    i
                    for i, (a, b) in enumerate(zip(python_labels, expected["labels"]))
                    if a != b
                ]
                print(f"LIBELLÉS {path.name}: lignes {differing[:5]}")

            python_offsets = [int(value) for value in label_offsets(lines)]
            if python_offsets != expected["labelOffsets"]:
                link_mismatches += 1
                differing = [
                    i
                    for i, (a, b) in enumerate(zip(python_offsets, expected["labelOffsets"]))
                    if a != b
                ]
                print(f"LIEN {path.name}: lignes {differing[:5]}")

    print(f"\n=== {tickets} tickets")
    print(f"  écart max de features de ligne : {worst_drift:.2e}")
    print(f"  écart max de features de mot   : {worst_word_drift:.2e}")
    print(f"  tickets aux features divergentes : {feature_mismatches}")
    print(f"  tickets aux features de mot divergentes : {word_mismatches}")
    print(f"  tickets aux rôles divergents     : {role_mismatches}")
    print(f"  tickets au lien divergent        : {link_mismatches}")
    print(f"  tickets au libellé divergent     : {label_mismatches}")
    return (
        1
        if feature_mismatches
        or role_mismatches
        or link_mismatches
        or word_mismatches
        or label_mismatches
        else 0
    )


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
