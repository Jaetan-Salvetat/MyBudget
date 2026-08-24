"""Score le flow complet exécuté on-device contre le golden.

Le harnais (mode « Suite complète ») dump par ticket la sortie ML Kit brute
plus la section `flow` : décision Dart (local / local_retry / confirm) et
extractions des deux passes. Ce script :

1. vérifie la parité Dart-device ↔ Python sur chaque passe (même OCR →
   même extraction, sinon bug de portage) ;
2. simule l'escalade cloud des tickets `confirm` : cache Gemini réel quand
   il existe (second run indépendant), sinon l'annotation golden du ticket —
   qui EST la sortie Gemini sauvegardée pour cette image. Sur les tickets en
   proxy golden, les corrections de l'étage cloud valent 0 par construction ;
   la répartition d'étages et le taux d'acceptation du checksum cloud, eux,
   restent honnêtes ;
3. score le résultat final de chaque étage contre le golden — la métrique
   produit : répartition des étages, corrections par ticket, faux
   auto-validés.

Nommage des images : t1test_<doc>.jpg / t1train_<doc>.jpg → golden
T1-test/<doc>.json / T1-train/<doc>.json.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from bench_flow import AMOUNT_EPSILON, StageStats, TicketRun, count_edits
from flow import AUTO_STAGES, CLOUD, CONFIRM, FlowPolicy
from llm_structure import parse_llm_receipt
from structure import extract_from_result

ROOT = Path(__file__).parent.parent
GOLDEN_DIRS = {"t1test": ROOT / "golden" / "T1-test", "t1train": ROOT / "golden" / "T1-train"}
CLOUD_CACHE = ROOT / "results" / "llm_gemini37_flash_flow"
LEGACY_CLOUD_CACHE = ROOT / "results" / "llm_gemini37_flash"
NAME_PATTERN = re.compile(r"^(t1test|t1train)_(\d+)\.jpg\.json$")

STAGE_NAMES = {"local": "local", "localRetry": "local_retry", "confirm": "confirm"}

POLICY = FlowPolicy(retry_must_not_lose_value=True)


@dataclass
class DeviceTicket:
    name: str
    split: str
    doc: str
    flow: dict
    golden: dict
    dump_path: Path


def load_tickets(results_dir: Path) -> list[DeviceTicket]:
    tickets = []
    for dump_path in sorted(results_dir.glob("*.json")):
        match = NAME_PATTERN.match(dump_path.name)
        if match is None:
            continue
        split, doc = match.groups()
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
    """Le même dump OCR doit produire la même extraction en Dart (device) et
    en Python : c'est le contrat du portage."""
    mismatches = 0
    for ticket in tickets:
        python_pass1 = _receipt_json(extract_from_result(ticket.dump_path))
        if python_pass1 != ticket.flow["pass1"]:
            mismatches += 1
            print(f"PARITE pass1 {ticket.name}:")
            print(f"  dart   {ticket.flow['pass1']}")
            print(f"  python {python_pass1}")
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


def _cloud_cache_path(ticket: DeviceTicket) -> Path | None:
    direct = CLOUD_CACHE / f"{ticket.split}_{ticket.doc}.json"
    if direct.exists():
        return direct
    if ticket.split == "t1test":
        legacy = LEGACY_CLOUD_CACHE / f"fr_genuine_{int(ticket.doc):04d}.json"
        if legacy.exists():
            return legacy
    return None


def _golden_cloud(ticket: DeviceTicket) -> tuple[list[tuple[float, float]], float | None]:
    receipt = ticket.golden["receipt"]
    items = [
        (round(float(i["amount"]), 2), round(abs(float(i["discount"])), 2))
        for i in receipt["items"]
    ]
    total = receipt.get("total")
    return items, (round(float(total), 2) if total is not None else None)


def resolve_outcome(ticket: DeviceTicket) -> tuple[str, list[tuple[float, float]]]:
    """Reprend la décision device et joue l'escalade cloud côté simulation :
    stage final + articles retenus."""
    stage = STAGE_NAMES[ticket.flow["stage"]]
    if stage in ("local", "local_retry"):
        items = ticket.flow["outcome"]["items"]
        return stage, [(i["amount"], i["discount"]) for i in items]

    cache = _cloud_cache_path(ticket)
    if cache is not None:
        cloud_items, cloud_total = parse_llm_receipt(
            json.loads(cache.read_text())
        )
    else:
        cloud_items, cloud_total = _golden_cloud(ticket)
    accepted = (
        cloud_total is not None
        and abs(
            round(sum(a - d for a, d in cloud_items), 2) - cloud_total
        )
        <= POLICY.tolerance
    )
    return (CLOUD if accepted else CONFIRM), cloud_items


def score(tickets: list[DeviceTicket]) -> None:
    stats = {stage: StageStats() for stage in [*AUTO_STAGES, CONFIRM]}
    cloud_proxied = 0
    for ticket in tickets:
        stage, got = resolve_outcome(ticket)
        if ticket.flow["stage"] == "confirm" and _cloud_cache_path(ticket) is None:
            cloud_proxied += 1
        expected = [
            round(float(item["amount"]), 2)
            for item in ticket.golden["receipt"]["items"]
        ]
        run = TicketRun(
            name=ticket.name,
            stage=stage,
            edits=count_edits(got, expected),
            double_validated=bool(ticket.golden.get("transcript_agrees")),
        )
        stats[stage].add(run)

    total = len(tickets)
    auto = sum(stats[stage].tickets for stage in AUTO_STAGES)
    retry_used = sum(1 for t in tickets if t.flow["retryUsed"])
    false_accepts = [
        run for stage in AUTO_STAGES for run in stats[stage].faulty
    ]

    print(f"\n=== flow on-device ({total} tickets)")
    for stage in [*AUTO_STAGES, CONFIRM]:
        stage_stats = stats[stage]
        if not stage_stats.tickets:
            continue
        mean = stage_stats.edits_total / stage_stats.tickets
        print(
            f"  {stage:<12}: {stage_stats.tickets:>4} "
            f"({stage_stats.tickets/total:.0%})  corr/ticket {mean:.2f}"
        )
    print(
        f"  auto-validés : {auto}/{total} ({auto/total:.0%}), "
        f"retry tentés : {retry_used}, cloud en proxy golden : {cloud_proxied}"
    )
    print(f"  FAUX AUTO-VALIDÉS : {len(false_accepts)}")
    for run in false_accepts:
        double = "double-validé" if run.double_validated else "gemini-seul"
        print(f"    {run.stage} {run.name}: {run.edits} corrections ({double})")

    latencies = sorted(
        t.flow["pass1Ms"] + (t.flow.get("retryMs") or 0) for t in tickets
    )
    if latencies:
        print(
            f"  latence pipeline : médiane {latencies[len(latencies)//2]} ms, "
            f"p95 {latencies[int(len(latencies)*0.95)]} ms"
        )


def main() -> None:
    results_dir = ROOT / "results" / (
        sys.argv[1] if len(sys.argv) > 1 else "device_flow"
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
