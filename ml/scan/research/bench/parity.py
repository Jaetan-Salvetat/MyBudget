"""Compare le pipeline Dart (tool/parity.dart) à la référence Python.

Ticket par ticket : extraction de la passe 1 champ à champ (store, date,
total, subtotal, payment, checksum, articles) et, avec `--model`, la
décision du flow local complet (stage, total, articles retenus) rejouée
avec le classifieur exporté. Zéro divergence attendue — le portage Dart est
spécifié par cette égalité.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from paths import DATA_DIR, MODELS_DIR, PIPELINE_DIR
from reference.local_flow import decide_local
from reference.structure import ExtractedReceipt, extract_from_result

MODEL_PATH = MODELS_DIR / "line_clf_v3.json"

DEFAULT_DIRS = [
    "results/device_fr",
    "results/device_fr_big",
    "results/device_fr_enhanced",
    "results/device_web",
    "results/emulator_all",
]


def python_receipt_json(receipt: ExtractedReceipt) -> dict:
    return {
        "store": receipt.store,
        "date": receipt.date,
        "total": receipt.total,
        "subtotal": receipt.subtotal,
        "payment": receipt.payment,
        "checksum_ok": receipt.checksum_ok,
        "items": [
            {"name": i.name, "amount": i.amount, "discount": i.discount}
            for i in receipt.items
        ],
    }


def python_flow_json(dump_path: Path) -> dict:
    outcome = decide_local(json.loads(dump_path.read_text()))
    return {
        "stage": outcome.stage,
        "total": outcome.total,
        "items": [{"amount": a, "discount": d} for a, d in outcome.items],
    }


def _report(key: str, field: str, python: dict, dart: dict) -> None:
    print(f"\nDIVERGENCE {field} {key}")
    for name, value in python.items():
        if value != dart.get(name):
            print(f"  python {name}: {value}")
            print(f"  dart   {name}: {dart.get(name)}")


def main() -> None:
    with_model = "--model" in sys.argv
    dirs = [a for a in sys.argv[1:] if a != "--model"] or DEFAULT_DIRS
    absolute_dirs = [str(DATA_DIR / d) for d in dirs]
    command = ["dart", "tool/parity.dart", *absolute_dirs]
    if with_model:
        command.append(f"--model={MODEL_PATH}")
    completed = subprocess.run(
        command, cwd=PIPELINE_DIR, capture_output=True, text=True, check=True
    )
    dart_results: dict[str, dict] = json.loads(completed.stdout)

    mismatches = 0
    for key, dart_entry in dart_results.items():
        python_pass1 = python_receipt_json(extract_from_result(Path(key)))
        if python_pass1 != dart_entry["pass1"]:
            mismatches += 1
            _report(key, "pass1", python_pass1, dart_entry["pass1"])
        if "flow" in dart_entry:
            python_flow = python_flow_json(Path(key))
            if python_flow != dart_entry["flow"]:
                mismatches += 1
                _report(key, "flow", python_flow, dart_entry["flow"])

    print(f"\n{len(dart_results)} tickets comparés, {mismatches} divergences")
    if mismatches:
        sys.exit(1)


if __name__ == "__main__":
    main()
