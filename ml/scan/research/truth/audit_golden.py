"""État de santé du golden, split par split.

Rapporte combien de tickets se jugent eux-mêmes, combien sont réparés par une
chaîne indépendante, et combien restent sans vérité. Écrit la liste de ces
derniers : un bench qui les compte comme des échecs mesure son golden, pas le
pipeline.

    uv run python -m truth.audit_golden [T1-test T1-train]
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

from paths import GOLDEN_DIR
from truth.golden import Verdict, best_reference
from truth.references import alternatives

INCONCLUSIVE_PATH = GOLDEN_DIR / "inconclusive.txt"
DEFAULT_SPLITS = ("T1-test", "T1-train")


def audit(split: str) -> tuple[Counter, list[str]]:
    counts: Counter[str] = Counter()
    inconclusive: list[str] = []
    for path in sorted((GOLDEN_DIR / split).glob("*.json")):
        golden = json.loads(path.read_text())["receipt"]
        _reference, verdict = best_reference(golden, alternatives(split, path.stem))
        counts[verdict.value] += 1
        if verdict is Verdict.INCONCLUSIVE:
            inconclusive.append(f"{split}/{path.stem}")
    return counts, inconclusive


def write_inconclusive(documents: list[str], path: Path = INCONCLUSIVE_PATH) -> None:
    header = (
        "# tickets sans vérité : ni le golden, ni la transcription, ni le corpus\n"
        "# annoté ne bouclent (truth.audit_golden). Comptés à part, jamais comme\n"
        "# des échecs du pipeline.\n"
    )
    path.write_text(header + "".join(f"{document}\n" for document in documents))


def load_inconclusive(path: Path = INCONCLUSIVE_PATH) -> set[str]:
    if not path.exists():
        return set()
    return {
        line.strip()
        for line in path.read_text().splitlines()
        if line.strip() and not line.startswith("#")
    }


def main(argv: list[str]) -> int:
    splits = argv or list(DEFAULT_SPLITS)
    everything: list[str] = []
    for split in splits:
        counts, inconclusive = audit(split)
        total = sum(counts.values())
        print(f"\n=== {split} ({total} tickets)")
        for verdict in Verdict:
            count = counts[verdict.value]
            if count:
                print(f"  {count:>4} ({count / total:5.1%})  {verdict.value}")
        everything.extend(inconclusive)
    write_inconclusive(everything)
    print(f"\n{len(everything)} tickets sans vérité écrits dans {INCONCLUSIVE_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
