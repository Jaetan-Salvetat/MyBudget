"""Bench du MODE LOCAL seul, rejoué offline depuis les dumps d'un run device.

Le checksum sert à afficher un niveau de confiance (jamais de validation sans
l'utilisateur). Ce bench mesure chaque évolution du tagger ou du décodeur sur
le pire-cas FindIt sans retoucher au device : les dumps OCR des deux passes
sont rejoués avec le flow courant.

Il n'y a plus d'étages à activer — le flow n'en a qu'un. Ce qui reste est la
**lecture** qui a porté la somme prouvée : passe 1, retry ou fusion.
`--split=t1train|t1test` isole un split ; les modèles s'entraînent sur
t1train, seul t1test mesure la généralisation.

Métriques : somme prouvée par lecture, faux vérifiés vs golden (la barre : 0
montant faux), corrections/ticket sur les tickets non vérifiés.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from bench.device_flow import load_tickets
from bench.scoring import StageStats, TicketRun, count_edits
from paths import RESULTS_DIR
from reference.local_flow import CONFIRM, VERIFIED_SOURCES, decide_local


def replay(results_dir: Path, split: str | None = None) -> list[TicketRun]:
    runs = []
    for ticket in load_tickets(results_dir):
        if split is not None and ticket.split != split:
            continue
        dump = json.loads(ticket.dump_path.read_text())
        outcome = decide_local(dump)
        expected = [
            round(float(i["amount"]), 2) for i in ticket.golden["receipt"]["items"]
        ]
        runs.append(
            TicketRun(
                name=ticket.name,
                stage=outcome.source,
                edits=count_edits(outcome.amounts, expected),
                double_validated=bool(ticket.golden.get("transcript_agrees")),
            )
        )
    return runs


def report(runs: list[TicketRun]) -> None:
    stats = {s: StageStats() for s in [*VERIFIED_SOURCES, CONFIRM]}
    for run in runs:
        stats[run.stage].add(run)
    total = len(runs)
    if not total:
        print("aucun ticket")
        return
    proved = sum(stats[s].tickets for s in VERIFIED_SOURCES)
    false_accepts = [r for s in VERIFIED_SOURCES for r in stats[s].faulty]
    confirm = stats[CONFIRM]
    by_source = ", ".join(
        f"{source} {stats[source].tickets}" for source in VERIFIED_SOURCES
    )
    print(f"=== mode local seul ({total} tickets)")
    print(f"  somme prouvée      : {proved}/{total} ({proved / total:.1%}) [{by_source}]")
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
    split = next(
        (f.removeprefix("--split=") for f in flags if f.startswith("--split=")), None
    )
    target = args[0] if args else "device_flow"
    report(replay(RESULTS_DIR / target, split=split))


if __name__ == "__main__":
    main()
