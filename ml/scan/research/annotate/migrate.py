"""Migration ponctuelle du corpus vers le format sans champ dérivé.

À jeter une fois passée. Réécrit chaque ticket au format de `record` : le
texte des lignes, l'index des entrées, `rotation`, `source` et `reason`
sortent du fichier, la provenance y entre.

Le prompt qui a produit ces annotations n'est pas connu — rien ne le notait
à l'époque. Il reste donc `null`, ce qui rend tout le corpus périmé au sens
de `--stale`. C'est la lecture honnête : on ne peut pas affirmer que le
prompt courant aurait donné la même chose.

    uv run python -m annotate.migrate [--dry-run]
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

from annotate import record
from annotate.client import MODEL
from paths import ANNOTATIONS_DIR

ANNOTATED_ON = "2026-08-25"
LEGACY_PROVENANCE = {"model": MODEL, "prompt": None, "date": ANNOTATED_ON}
DERIVED_KEYS = ("reason", "rotation", "source")


def _positional(annotation: dict) -> list[dict]:
    ordered = sorted(annotation.get("lines") or [], key=lambda entry: entry["index"])
    return [{k: v for k, v in entry.items() if k != "index"} for entry in ordered]


def migrate(path: Path, dry_run: bool) -> str:
    payload = json.loads(path.read_text())
    if "provenance" in payload:
        return "déjà migré"
    if "annotation" not in payload or "lines" not in payload:
        return "sans annotation"
    if dry_run:
        return "à migrer"

    annotation = payload["annotation"]
    record.write(
        path,
        image=payload["image"],
        lines=record.lines_of(payload),
        entries=_positional(annotation),
        store=annotation.get("store"),
        date=annotation.get("date"),
        provenance=LEGACY_PROVENANCE,
    )
    return "migré"


def main(argv: list[str]) -> int:
    dry_run = "--dry-run" in argv
    outcomes: Counter[str] = Counter()
    for path in sorted(ANNOTATIONS_DIR.rglob("*.json")):
        outcomes[migrate(path, dry_run)] += 1
    for outcome, count in outcomes.most_common():
        print(f"  {count:5}  {outcome}")

    leftovers = Counter()
    for path in ANNOTATIONS_DIR.rglob("*.json"):
        payload = json.loads(path.read_text())
        leftovers.update(key for key in DERIVED_KEYS if key in payload)
        leftovers.update(
            "index" for line in payload.get("annotation", {}).get("lines") or []
            if "index" in line
        )
        leftovers.update("text" for line in payload["lines"] if "text" in line)
    print(f"  champs dérivés restants : {dict(leftovers) or 'aucun'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
