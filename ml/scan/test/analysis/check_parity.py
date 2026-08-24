"""Compare l'extraction Dart (tool/parity.dart) à la référence Python.

Champ à champ, ticket par ticket : store, date, total, subtotal, payment,
checksum et la liste exacte des articles. Zéro divergence attendue — le
portage Dart est spécifié par cette égalité.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from structure import ExtractedReceipt, extract_from_result

ROOT = Path(__file__).parent.parent
PIPELINE_DIR = ROOT.parent / "pipeline"

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


def main() -> None:
    dirs = sys.argv[1:] or DEFAULT_DIRS
    absolute_dirs = [str(ROOT / d) for d in dirs]
    completed = subprocess.run(
        ["dart", "tool/parity.dart", *absolute_dirs],
        cwd=PIPELINE_DIR,
        capture_output=True,
        text=True,
        check=True,
    )
    dart_results: dict[str, dict] = json.loads(completed.stdout)

    mismatches = 0
    compared = 0
    for key, dart_receipt in dart_results.items():
        python_receipt = python_receipt_json(extract_from_result(Path(key)))
        compared += 1
        if python_receipt == dart_receipt:
            continue
        mismatches += 1
        print(f"\nDIVERGENCE {key}")
        for field in python_receipt:
            if python_receipt[field] != dart_receipt.get(field):
                print(f"  python {field}: {python_receipt[field]}")
                print(f"  dart   {field}: {dart_receipt.get(field)}")

    print(f"\n{compared} tickets comparés, {mismatches} divergences")
    if mismatches:
        sys.exit(1)


if __name__ == "__main__":
    main()
