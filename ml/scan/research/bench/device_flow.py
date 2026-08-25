"""Score le flow local complet exécuté on-device contre le golden.

Le harnais (mode « Suite complète ») dump par ticket la sortie ML Kit brute
plus la section `flow` : décision Dart (local / local_retry / local_ml /
local_dp / confirm) et extractions des deux passes. Ce script :

1. vérifie la parité Dart-device ↔ Python : même dump OCR → même extraction
   de la passe 1 ET même décision de flow (stage, total, articles), sinon
   bug de portage ;
2. score la sortie de chaque étage contre le golden — la métrique produit :
   répartition des étages, corrections par ticket, faux vérifiés.

Nommage des images : t1test_<doc>.jpg / t1train_<doc>.jpg → golden
T1-test/<doc>.json / T1-train/<doc>.json.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from bench.flow import StageStats, TicketRun, count_edits
from paths import GOLDEN_DIR, RESULTS_DIR
from reference.local_flow import CONFIRM, VERIFIED_STAGES, decide_local
from reference.structure import extract_from_result

GOLDEN_DIRS = {
    "t1test": GOLDEN_DIR / "T1-test",
    "t1train": GOLDEN_DIR / "T1-train",
}
NAME_PATTERN = re.compile(r"^(t1test|t1train)_(\d+)\.jpg\.json$")
EXCLUDED_PATH = GOLDEN_DIR / "excluded.txt"

STAGE_NAMES = {
    "local": "local",
    "localRetry": "local_retry",
    "local_retry": "local_retry",
    "local_ml": "local_ml",
    "local_dp": "local_dp",
    "localFused": "local_fused",
    "local_fused": "local_fused",
    "confirm": "confirm",
}


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


def check_parity(tickets: list[DeviceTicket]) -> int:
    """Le même dump OCR doit produire la même extraction et la même décision
    en Dart (device) et en Python : c'est le contrat du portage."""
    mismatches = 0
    for ticket in tickets:
        dump = json.loads(ticket.dump_path.read_text())
        python_pass1 = _receipt_json(extract_from_result(ticket.dump_path))
        if python_pass1 != ticket.flow["pass1"]:
            mismatches += 1
            print(f"PARITE pass1 {ticket.name}:")
            print(f"  dart   {ticket.flow['pass1']}")
            print(f"  python {python_pass1}")
        python_flow = decide_local(dump)
        device_flow = _device_outcome(ticket)
        if (python_flow.stage, python_flow.amounts, python_flow.total) != device_flow:
            mismatches += 1
            print(f"PARITE flow {ticket.name}:")
            print(f"  dart   {device_flow}")
            print(
                f"  python {(python_flow.stage, python_flow.amounts, python_flow.total)}"
            )
    return mismatches


def _receipt_json(receipt) -> dict:
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


def _device_outcome(
    ticket: DeviceTicket,
) -> tuple[str, list[tuple[float, float]], float | None]:
    outcome = ticket.flow["outcome"]
    return (
        STAGE_NAMES[outcome["stage"]],
        [(round(i["amount"], 2), round(i["discount"], 2)) for i in outcome["items"]],
        outcome["total"],
    )


def score(tickets: list[DeviceTicket]) -> None:
    stats = {stage: StageStats() for stage in [*VERIFIED_STAGES, CONFIRM]}
    for ticket in tickets:
        stage, got, _total = _device_outcome(ticket)
        expected = [
            round(float(item["amount"]), 2)
            for item in ticket.golden["receipt"]["items"]
        ]
        stats[stage].add(
            TicketRun(
                name=ticket.name,
                stage=stage,
                edits=count_edits(got, expected),
                double_validated=bool(ticket.golden.get("transcript_agrees")),
            )
        )

    total = len(tickets)
    verified = sum(stats[stage].tickets for stage in VERIFIED_STAGES)
    retry_used = sum(1 for t in tickets if t.flow["retryUsed"])
    false_accepts = [run for stage in VERIFIED_STAGES for run in stats[stage].faulty]

    print(f"\n=== flow on-device ({total} tickets)")
    for stage in [*VERIFIED_STAGES, CONFIRM]:
        stage_stats = stats[stage]
        if not stage_stats.tickets:
            continue
        mean = stage_stats.edits_total / stage_stats.tickets
        print(
            f"  {stage:<12}: {stage_stats.tickets:>4} "
            f"({stage_stats.tickets / total:.0%})  corr/ticket {mean:.2f}"
        )
    print(
        f"  vérifiés : {verified}/{total} ({verified / total:.1%}), "
        f"retry tentés : {retry_used}"
    )
    print(f"  FAUX VÉRIFIÉS : {len(false_accepts)}")
    for run in false_accepts:
        double = "double-validé" if run.double_validated else "gemini-seul"
        print(f"    {run.stage} {run.name}: {run.edits} corrections ({double})")

    latencies = sorted(
        t.flow["pass1Ms"] + (t.flow.get("retryMs") or 0) for t in tickets
    )
    if latencies:
        print(
            f"  latence pipeline : médiane {latencies[len(latencies) // 2]} ms, "
            f"p95 {latencies[int(len(latencies) * 0.95)]} ms"
        )


def main() -> None:
    results_dir = (
        RESULTS_DIR / (sys.argv[1] if len(sys.argv) > 1 else "device_flow")
    )
    tickets = load_tickets(results_dir)
    if not tickets:
        print(f"aucun ticket exploitable dans {results_dir}")
        sys.exit(1)

    mismatches = check_parity(tickets)
    print(f"parité Dart-device ↔ Python : {mismatches} divergences / {len(tickets)}")

    score(tickets)
    if mismatches:
        sys.exit(1)


if __name__ == "__main__":
    main()
