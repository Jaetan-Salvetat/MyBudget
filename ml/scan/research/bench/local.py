"""Bench du MODE LOCAL seul, rejoué offline depuis les dumps d'un run device.

Le checksum sert à afficher un niveau de confiance (jamais de validation
sans l'utilisateur). Ce bench mesure chaque évolution des règles, du
classifieur ou du décodeur sur le pire-cas FindIt sans retoucher au device
(les dumps OCR des deux passes sont rejoués avec le flow courant).

Étages : local (règles) → retry → ml (argmax du classifieur) → dp (décodage
sous contrainte checksum). Options : `--ml` active les étages classifieur,
`--no-dp` désactive le décodeur, `--v2` force l'ancien classifieur,
`--split=t1train|t1test` isole un split (les modèles s'entraînent sur
t1train : seul t1test mesure la généralisation).

Métriques : checksum OK (tous étages), faux vérifiés vs golden (la barre :
0 montant faux), corrections/ticket sur les tickets non vérifiés.
"""

from __future__ import annotations

import sys
from pathlib import Path

from bench.device_flow import load_tickets
from bench.flow import StageStats, TicketRun, count_edits
from paths import RESULTS_DIR
from reference.local_flow import VERIFIED_STAGES, decide_local

LOCAL_STAGES = VERIFIED_STAGES
USE_DP = "--no-dp" not in sys.argv
if "--v2" in sys.argv:
    import structure_ml

    structure_ml.ACTIVE_VERSION = "v2"


def replay(
    results_dir: Path, use_ml: bool = False, split: str | None = None
) -> list[TicketRun]:
    import json

    runs = []
    for ticket in load_tickets(results_dir):
        if split is not None and ticket.split != split:
            continue
        dump = json.loads(ticket.dump_path.read_text())
        outcome = decide_local(dump, use_ml=use_ml, use_dp=USE_DP)
        expected = [
            round(float(i["amount"]), 2) for i in ticket.golden["receipt"]["items"]
        ]
        runs.append(
            TicketRun(
                name=ticket.name,
                stage=outcome.stage,
                edits=count_edits(outcome.items, expected),
                double_validated=bool(ticket.golden.get("transcript_agrees")),
            )
        )
    return runs


def report(runs: list[TicketRun]) -> None:
    stats = {s: StageStats() for s in [*LOCAL_STAGES, "confirm"]}
    for run in runs:
        stats[run.stage].add(run)
    total = len(runs)
    auto = sum(stats[s].tickets for s in LOCAL_STAGES)
    false_accepts = [r for s in LOCAL_STAGES for r in stats[s].faulty]
    confirm = stats["confirm"]
    print(f"=== mode local seul ({total} tickets)")
    print(
        f"  validation directe : {auto}/{total} ({auto / total:.1%}) "
        f"[local {stats['local'].tickets}, retry {stats['local_retry'].tickets}, "
        f"ml {stats['local_ml'].tickets}, dp {stats['local_dp'].tickets}, "
        f"fused {stats['local_fused'].tickets}]"
    )
    mean = confirm.edits_total / confirm.tickets if confirm.tickets else 0.0
    print(
        f"  confirmation       : {confirm.tickets} ({confirm.tickets / total:.1%}), "
        f"corr/ticket {mean:.2f}"
    )
    print(f"  FAUX AUTO-VALIDÉS  : {len(false_accepts)}")
    for run in false_accepts:
        double = "double-validé" if run.double_validated else "gemini-seul"
        print(f"    {run.stage} {run.name}: {run.edits} corr. ({double})")


def main() -> None:
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    use_ml = "--ml" in flags
    split = next(
        (f.removeprefix("--split=") for f in flags if f.startswith("--split=")), None
    )
    target = args[0] if args else "device_flow"
    report(replay(RESULTS_DIR / target, use_ml=use_ml, split=split))


if __name__ == "__main__":
    main()
