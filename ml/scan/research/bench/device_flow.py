"""Les tickets d'un run device : dump OCR apparié à sa vérité golden.

Chaque dump porte la sortie ML Kit des deux passes, et une section `flow`
qui archive la décision prise sur l'appareil au moment du run. C'est ce
chargeur que tous les benchs du mode local consomment : `local.py` rejoue le
flow courant dessus, `failures.py` classe ses échecs, `diagnose.py` les
détaille.

**La décision archivée n'est plus comparable.** Elle a été prise par une
cascade à six étages qui n'existe plus, par un harnais Flutter on-device qui
n'existe plus non plus — la parité Dart↔Python se mesure aujourd'hui par
`bench/parity.py`, qui rejoue le portage courant sur ces mêmes dumps. Ce qui
reste utilisable ici est l'entrée : les mots OCR et les latences de lecture.

Nommage des images : t1test_<doc>.jpg / t1train_<doc>.jpg → golden
T1-test/<doc>.json / T1-train/<doc>.json.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from paths import GOLDEN_DIR, RESULTS_DIR

GOLDEN_DIRS = {
    "t1test": GOLDEN_DIR / "T1-test",
    "t1train": GOLDEN_DIR / "T1-train",
}
NAME_PATTERN = re.compile(r"^(t1test|t1train)_(\d+)\.jpg\.json$")
EXCLUDED_PATH = GOLDEN_DIR / "excluded.txt"

@dataclass
class DeviceTicket:
    name: str
    split: str
    doc: str
    flow: dict
    golden: dict
    dump_path: Path


def parse_excluded(text: str) -> set[str]:
    names = set()
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        names.add(stripped.split()[0])
    return names


def load_excluded(path: Path = EXCLUDED_PATH) -> set[str]:
    if not path.exists():
        return set()
    return parse_excluded(path.read_text())


def load_tickets(
    results_dir: Path, excluded: set[str] | None = None
) -> list[DeviceTicket]:
    if excluded is None:
        excluded = load_excluded()
    tickets = []
    for dump_path in sorted(results_dir.glob("*.json")):
        match = NAME_PATTERN.match(dump_path.name)
        if match is None:
            continue
        split, doc = match.groups()
        if f"{split}_{doc}" in excluded:
            continue
        golden_path = GOLDEN_DIRS[split] / f"{doc}.json"
        if not golden_path.exists():
            print(f"golden manquant pour {dump_path.name}")
            continue
        data = json.loads(dump_path.read_text())
        if "flow" not in data:
            print(f"section flow manquante dans {dump_path.name}")
            continue
        tickets.append(
            DeviceTicket(
                name=dump_path.name.replace(".jpg.json", ""),
                split=split,
                doc=doc,
                flow=data["flow"],
                golden=json.loads(golden_path.read_text()),
                dump_path=dump_path,
            )
        )
    return tickets


def main() -> None:
    """Ce que le run contient — pas ce qu'il décidait."""
    results_dir = RESULTS_DIR / (sys.argv[1] if len(sys.argv) > 1 else "device_flow")
    tickets = load_tickets(results_dir)
    if not tickets:
        print(f"aucun ticket exploitable dans {results_dir}")
        sys.exit(1)

    print(f"=== {results_dir.name} : {len(tickets)} tickets à vérité golden")
    retried = sum(1 for t in tickets if t.flow.get("retryUsed"))
    print(f"  seconde passe tentée au run : {retried}")
    latencies = sorted(
        t.flow["pass1Ms"] + (t.flow.get("retryMs") or 0)
        for t in tickets
        if t.flow.get("pass1Ms") is not None
    )
    if latencies:
        print(
            f"  latence OCR device : médiane {latencies[len(latencies) // 2]} ms, "
            f"p95 {latencies[int(len(latencies) * 0.95)]} ms"
        )
    print("  décision du flow courant : uv run python -m bench.local")


if __name__ == "__main__":
    main()
