"""Confronte les annotations acceptées à la vérité golden de FindIt.

Le filtre checksum garantit qu'une annotation est *cohérente* ; il ne dit
pas qu'elle est *juste*. Sur les splits FindIt, une vérité indépendante
existe : ce script compare les articles annotés à ceux du golden, ticket par
ticket. C'est la seule mesure qui dise si l'auto-annotation mérite de servir
de supervision.

    uv run python -m annotate.audit [t1train|t1test]
"""

from __future__ import annotations

import json
import sys
from collections import Counter

from annotate.run import ANNOTATIONS_DIR
from annotate.schema import DISCOUNT, ITEM
from bench.flow import count_edits
from paths import GOLDEN_DIR

SPLIT_DIRS = {"t1train": "T1-train", "t1test": "T1-test"}


def annotated_items(annotation: dict) -> list[tuple[float, float]]:
    """Articles annotés, remise comprise — au format attendu par le scoreur
    du flow : la remise portée par une ligne `discount` revient à l'article
    qui la précède."""
    items: list[tuple[float, float]] = []
    for entry in annotation["lines"]:
        amount = entry.get("amount") or 0.0
        if entry["role"] == ITEM:
            items.append((round(amount, 2), round(entry.get("discount") or 0.0, 2)))
        elif entry["role"] == DISCOUNT and items:
            amount_, discount = items[-1]
            items[-1] = (amount_, round(discount + amount, 2))
    return items


def main(argv: list[str]) -> int:
    split = argv[0] if argv else "t1train"
    directory = ANNOTATIONS_DIR / SPLIT_DIRS[split]
    golden_dir = GOLDEN_DIR / SPLIT_DIRS[split]

    edits: Counter[int] = Counter()
    audited = 0
    faulty: list[tuple[str, int]] = []
    for path in sorted(directory.glob("*.json")):
        record = json.loads(path.read_text())
        if record.get("reason") is not None:
            continue
        golden_path = golden_dir / f"{path.stem}.json"
        if not golden_path.exists():
            continue
        golden = json.loads(golden_path.read_text())
        expected = [
            round(float(item["amount"]), 2) for item in golden["receipt"]["items"]
        ]
        wrong = count_edits(annotated_items(record["annotation"]), expected)
        edits[wrong] += 1
        audited += 1
        if wrong:
            faulty.append((path.stem, wrong))

    if not audited:
        print("aucune annotation acceptée à auditer")
        return 1
    exact = edits[0]
    print(f"=== {audited} annotations acceptées, confrontées au golden {split}")
    print(f"  exactes : {exact}/{audited} ({exact / audited:.1%})")
    for wrong, count in sorted(edits.items()):
        if wrong:
            print(f"  {wrong} écart(s) : {count} tickets")
    for name, wrong in faulty[:10]:
        print(f"    {name} : {wrong}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
