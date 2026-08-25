"""Rejoue le filtre sur les annotations déjà obtenues.

Le filtre évolue ; l'annotation, elle, est acquise. Ce script recalcule la
raison de rejet sans rappeler le modèle — indispensable pour faire bouger un
garde-fou sans repayer le corpus entier.

    uv run python -m annotate.revalidate
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

from annotate.run import ANNOTATIONS_DIR
from annotate.validate import rejection_reason
from reference.lines import PhysicalLine, Word

REASON_SHAPE = re.compile(r"[-\d.,]+")


def _lines_of(record: dict) -> list[PhysicalLine]:
    return [
        PhysicalLine(
            words=[
                Word(
                    text=word["text"],
                    left=word["box"][0],
                    top=word["box"][1],
                    right=word["box"][2],
                    bottom=word["box"][3],
                    confidence=word["confidence"],
                )
                for word in line["words"]
            ]
        )
        for line in record["lines"]
    ]


def main(argv: list[str]) -> int:
    directory = Path(argv[0]) if argv else ANNOTATIONS_DIR
    shapes: Counter[str] = Counter()
    accepted = 0
    total = 0
    for path in sorted(directory.rglob("*.json")):
        record = json.loads(path.read_text())
        if "annotation" not in record:
            continue
        total += 1
        reason = rejection_reason(record["annotation"], _lines_of(record))
        record["reason"] = reason
        path.write_text(json.dumps(record, ensure_ascii=False))
        if reason is None:
            accepted += 1
        else:
            shapes[REASON_SHAPE.sub("N", reason)] += 1

    print(f"=== {total} annotations revalidées")
    print(f"  acceptées : {accepted} ({accepted / max(total, 1):.0%})")
    for shape, count in shapes.most_common():
        print(f"  {count:>4}  {shape}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
