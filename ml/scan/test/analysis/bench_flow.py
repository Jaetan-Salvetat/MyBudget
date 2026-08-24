"""Simule le flow produit complet hors-ligne et le score contre le golden.

Rejoue, depuis les caches (OCR device, OCR retry prétraité, sorties Gemini),
le parcours exact d'un scan : local → retry → escalade cloud → confirmation.
Chaque ticket finit dans un étage ; on mesure la répartition, les corrections
restantes par étage et surtout les faux auto-validés (données fausses
acceptées sans écran de vérification), le tout sous plusieurs politiques
d'acceptation pour calibrer tolérance, cross-check et pré-remplissage.

Caveat étage cloud : le golden a été annoté par le même run Gemini que le
cache d'escalade — les corrections de cet étage vs golden valent 0 par
construction. La mesure indépendante de cet étage est bench_gemini.py
(0,00 corr./ticket vs transcriptions) ; ici le golden sert de vérité aux
étages locaux et à la répartition du flow.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

from flow import AUTO_STAGES, CONFIRM, FlowPolicy, decide
from llm_structure import parse_llm_receipt
from structure import ExtractedReceipt, extract_from_result

ROOT = Path(__file__).parent.parent
OCR_DIRS = [ROOT / "results" / "device_fr", ROOT / "results" / "device_fr_big"]
ENHANCED_DIR = ROOT / "results" / "device_fr_enhanced"
CLOUD_DIR = ROOT / "results" / "llm_gemini37_flash"
GOLDEN_DIR = ROOT / "golden" / "T1-test"

AMOUNT_EPSILON = 0.005
STAGE_ORDER = [*AUTO_STAGES, CONFIRM]


@dataclass
class TicketRun:
    name: str
    stage: str
    edits: int
    double_validated: bool


@dataclass
class StageStats:
    tickets: int = 0
    edits_total: int = 0
    faulty: list[TicketRun] = field(default_factory=list)

    def add(self, run: TicketRun) -> None:
        self.tickets += 1
        self.edits_total += run.edits
        if run.edits:
            self.faulty.append(run)


def covered_receipts() -> list[tuple[str, Path, Path]]:
    receipts: dict[str, tuple[str, Path, Path]] = {}
    for ocr_dir in OCR_DIRS:
        for result in sorted(ocr_dir.glob("fr_genuine_*.json")):
            name = result.name.replace(".jpg.json", "")
            if name in receipts:
                continue
            doc_id = str(int(name.split("_")[-1]))
            golden = GOLDEN_DIR / f"{doc_id}.json"
            if golden.exists():
                receipts[name] = (name, result, golden)
    return list(receipts.values())


def _load_retry(name: str) -> ExtractedReceipt | None:
    path = ENHANCED_DIR / f"{name}.jpg.json"
    return extract_from_result(path) if path.exists() else None


def _load_cloud(name: str) -> tuple[list[tuple[float, float]] | None, float | None]:
    path = CLOUD_DIR / f"{name}.json"
    if not path.exists():
        return None, None
    items, total = parse_llm_receipt(json.loads(path.read_text()))
    return items, total


def count_edits(
    got: list[tuple[float, float]], expected: list[float]
) -> int:
    """Corrections utilisateur : articles attendus manqués + extraits en trop,
    à impact monétaire réel. Deux équivalences neutralisées (audit du run
    device) : un attendu à 0,00 € manqué ne coûte rien, et un attendu négatif
    est équivalent à une remise du même montant sur un article extrait."""
    remaining = list(expected)
    discounts = [d for _amount, d in got if d > 0]
    wrong = 0
    for amount, _discount in got:
        hit = next(
            (p for p in remaining if abs(p - amount) < AMOUNT_EPSILON), None
        )
        if hit is not None:
            remaining.remove(hit)
        else:
            wrong += 1
    misses = 0
    for pending in remaining:
        if abs(pending) < AMOUNT_EPSILON:
            continue
        if pending < 0:
            refund = next(
                (d for d in discounts if abs(d + pending) < AMOUNT_EPSILON),
                None,
            )
            if refund is not None:
                discounts.remove(refund)
                continue
        misses += 1
    return wrong + misses


def run_flow(policy: FlowPolicy) -> list[TicketRun]:
    runs: list[TicketRun] = []
    for name, ocr_path, golden_path in covered_receipts():
        golden = json.loads(golden_path.read_text())
        expected = [
            round(float(item["amount"]), 2)
            for item in golden["receipt"]["items"]
        ]

        local = extract_from_result(ocr_path)
        retry = _load_retry(name)
        cloud_items, cloud_total = _load_cloud(name)
        outcome = decide(local, retry, cloud_items, cloud_total, policy)

        runs.append(
            TicketRun(
                name=name,
                stage=outcome.stage,
                edits=count_edits(outcome.items, expected),
                double_validated=bool(golden.get("transcript_agrees")),
            )
        )
    return runs


def report(label: str, runs: list[TicketRun]) -> None:
    stats = {stage: StageStats() for stage in STAGE_ORDER}
    for run in runs:
        stats[run.stage].add(run)

    total = len(runs)
    auto = sum(stats[stage].tickets for stage in AUTO_STAGES)
    cloud_calls = total - stats["local"].tickets - stats["local_retry"].tickets
    false_accepts = [
        run
        for stage in AUTO_STAGES
        for run in stats[stage].faulty
    ]

    print(f"\n=== {label} ({total} tickets)")
    for stage in STAGE_ORDER:
        stage_stats = stats[stage]
        if not stage_stats.tickets:
            continue
        mean = stage_stats.edits_total / stage_stats.tickets
        print(
            f"  {stage:<12}: {stage_stats.tickets:>3} ({stage_stats.tickets/total:.0%})"
            f"  corr/ticket {mean:.2f}"
        )
    print(
        f"  auto-validés : {auto}/{total} ({auto/total:.0%}), "
        f"appels cloud : {cloud_calls} ({cloud_calls/total:.0%})"
    )
    print(f"  FAUX AUTO-VALIDÉS : {len(false_accepts)}")
    for run in false_accepts:
        double = "double-validé" if run.double_validated else "gemini-seul"
        print(f"    {run.stage} {run.name}: {run.edits} corrections ({double})")


POLICIES = [
    ("strict, pré-rempli cloud", FlowPolicy()),
    (
        "strict + garde-fou retry",
        FlowPolicy(retry_must_not_lose_value=True),
    ),
    (
        "garde-fou retry + cross-check total local",
        FlowPolicy(retry_must_not_lose_value=True, cross_check_local_total=True),
    ),
    (
        "garde-fou retry + tolérance 2 centimes",
        FlowPolicy(retry_must_not_lose_value=True, tolerance=0.02),
    ),
    (
        "garde-fou retry, pré-rempli local",
        FlowPolicy(retry_must_not_lose_value=True, confirm_prefill="local"),
    ),
]


def main() -> None:
    for label, policy in POLICIES:
        report(label, run_flow(policy))


if __name__ == "__main__":
    main()
