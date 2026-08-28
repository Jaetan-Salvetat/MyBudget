"""Écrit la référence de parité Python → Dart de `normalize_receipt_line`.

Tous les libellés distincts des golden FindIt, plus les en-têtes d'enseigne :
le port Dart (`ReceiptLineNormalizer`) doit produire exactement la même
chaîne, sinon le modèle recevrait à l'inférence un texte qu'il n'a pas vu à
l'entraînement.
"""

import json
import sys

from paths import PROJECT_ROOT, SCAN_GOLDEN_DIR
from serving.normalize import normalize_receipt_line

GOLDEN_DIR = SCAN_GOLDEN_DIR
FIXTURE_PATH = (
    PROJECT_ROOT
    / "ml/scan/pipeline/test/fixtures/receipt_line_normalization.json"
)


def main() -> None:
    lines: set[str] = set()
    for path in sorted(GOLDEN_DIR.glob("T1-*/*.json")):
        receipt = json.loads(path.read_text(encoding="utf-8"))["receipt"]
        if receipt.get("store"):
            lines.add(receipt["store"])
        lines.update(item["name"] for item in receipt["items"])
    pairs = [[line, normalize_receipt_line(line)] for line in sorted(lines)]
    FIXTURE_PATH.parent.mkdir(parents=True, exist_ok=True)
    FIXTURE_PATH.write_text(json.dumps(pairs, ensure_ascii=False, indent=0), encoding="utf-8")
    print(f"{len(pairs)} lignes → {FIXTURE_PATH.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    sys.exit(main())
