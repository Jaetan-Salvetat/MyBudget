"""Bench du MODE LOCAL seul, rejoué offline depuis les dumps d'un run device.

L'app est locale-first : pas d'escalade cloud, un checksum KO = écran de
confirmation. La cible produit est ~99 % de validation directe sur tickets
frais ; ce bench mesure chaque évolution des règles sur le pire-cas FindIt
sans retoucher au device (les dumps OCR des deux passes sont rejoués avec
les règles courantes).

Métriques : validation directe (local + retry, garde-fou compris), faux
auto-validés vs golden (la barre : ~0), corrections/ticket sur l'écran de
confirmation.
"""

from __future__ import annotations

import sys
from pathlib import Path

from bench_flow import StageStats, TicketRun, count_edits
from flow import FlowPolicy, decide
from lines import cluster_lines, deskew_words, load_words, median_angle
from score_device_flow import load_tickets
from structure import extract

ROOT = Path(__file__).parent.parent
POLICY = FlowPolicy(retry_must_not_lose_value=True, confirm_prefill="local")

LOCAL_STAGES = ("local", "local_retry", "local_ml")


def _clustered(dump: dict):
    angles = [
        line["angle"]
        for block in dump["blocks"]
        for line in block["lines"]
        if line.get("angle") is not None
    ]
    words, _ = _words_of(dump)
    angle = sorted(angles)[len(angles) // 2] if angles else 0.0
    return cluster_lines(deskew_words(words, angle))


def _extract_pass(dump: dict):
    return extract(_clustered(dump))


def _words_of(dump: dict):
    from lines import Word

    words = []
    for block in dump["blocks"]:
        for line in block["lines"]:
            for element in line["elements"]:
                left, top, right, bottom = element["box"]
                words.append(
                    Word(
                        text=element["text"],
                        left=left,
                        top=top,
                        right=right,
                        bottom=bottom,
                        confidence=element.get("confidence"),
                    )
                )
    return words, dump


def replay(results_dir: Path, use_ml: bool = False) -> list[TicketRun]:
    import json

    runs = []
    for ticket in load_tickets(results_dir):
        dump = json.loads(ticket.dump_path.read_text())
        local = _extract_pass(dump)
        retry = (
            _extract_pass(dump["ocrRetry"]) if "ocrRetry" in dump else None
        )
        outcome = decide(local, retry, None, None, POLICY)
        stage = outcome.stage if outcome.stage in LOCAL_STAGES else "confirm"
        got = outcome.items
        if stage == "confirm" and use_ml:
            rescue = _ml_rescue(dump)
            if rescue is not None:
                stage = "local_ml"
                got = [(i.amount, i.discount) for i in rescue.items]
        expected = [
            round(float(i["amount"]), 2)
            for i in ticket.golden["receipt"]["items"]
        ]
        runs.append(
            TicketRun(
                name=ticket.name,
                stage=stage,
                edits=count_edits(got, expected),
                double_validated=bool(ticket.golden.get("transcript_agrees")),
            )
        )
    return runs


def _ml_rescue(dump: dict):
    from structure import merge_price_fragments
    from structure_ml import extract_ml

    for source in [dump] + ([dump["ocrRetry"]] if "ocrRetry" in dump else []):
        merged = [
            merge_price_fragments(line) for line in _clustered(source)
        ]
        receipt = extract_ml(merged)
        if receipt is not None and receipt.checksum_ok:
            return receipt
    return None


def report(runs: list[TicketRun]) -> None:
    stats = {s: StageStats() for s in [*LOCAL_STAGES, "confirm"]}
    for run in runs:
        stats[run.stage].add(run)
    total = len(runs)
    auto = sum(stats[s].tickets for s in LOCAL_STAGES)
    false_accepts = [
        r for s in LOCAL_STAGES for r in stats[s].faulty
    ]
    confirm = stats["confirm"]
    print(f"=== mode local seul ({total} tickets)")
    print(
        f"  validation directe : {auto}/{total} ({auto/total:.1%}) "
        f"[local {stats['local'].tickets}, retry {stats['local_retry'].tickets}, "
        f"ml {stats['local_ml'].tickets}]"
    )
    mean = confirm.edits_total / confirm.tickets if confirm.tickets else 0.0
    print(
        f"  confirmation       : {confirm.tickets} ({confirm.tickets/total:.1%}), "
        f"corr/ticket {mean:.2f}"
    )
    print(f"  FAUX AUTO-VALIDÉS  : {len(false_accepts)}")
    for run in false_accepts:
        double = "double-validé" if run.double_validated else "gemini-seul"
        print(f"    {run.stage} {run.name}: {run.edits} corr. ({double})")


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--ml"]
    use_ml = "--ml" in sys.argv
    target = args[0] if args else "device_flow"
    report(replay(ROOT / "results" / target, use_ml=use_ml))


if __name__ == "__main__":
    main()
