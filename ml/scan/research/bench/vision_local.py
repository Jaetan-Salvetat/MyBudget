"""Bench du mode local depuis les images, OCR Apple Vision sur le Mac.

Le bench de référence (`bench/local.py`) rejoue des dumps ML Kit capturés
sur device : il mesure la structuration, jamais l'image. Celui-ci part des
JPEG du corpus FindIt et exécute l'OCR ici, ce qui permet d'itérer sur un
ticket neuf sans téléphone et de séparer ce qui est un défaut de l'OCR d'un
défaut des règles.

    uv run python -m bench.vision_local [--split t1test|t1train] [--limit N]
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from bench.exactness import ExtractedName, receipt_exactness
from bench.flow import StageStats, TicketRun, count_edits
from ocr.pipeline import dump_for
from paths import FINDIT_DIR, GOLDEN_DIR, RESULTS_DIR
from reference.header_ml import date_of, role_probabilities, store_of
from reference.labels_ml import label_offsets, relabel
from reference.local_flow import CONFIRM, VERIFIED_STAGES, clustered_lines, decide_local
from reference.spans_ml import label_probabilities
from truth.golden import Verdict, best_reference
from truth.references import alternatives

SPLIT_DIRS = {"t1test": "T1-test", "t1train": "T1-train"}
OUTPUT_DIR = RESULTS_DIR / "vision_local"


def _images(split: str, limit: int | None) -> list[Path]:
    directory = FINDIT_DIR / SPLIT_DIRS[split] / "img"
    golden_dir = GOLDEN_DIR / SPLIT_DIRS[split]
    images = [
        image
        for image in sorted(directory.glob("*.jpg"))
        if (golden_dir / f"{image.stem}.json").exists()
    ]
    return images[:limit] if limit else images


def _run_one(image: Path) -> dict:
    dump = dump_for(image)
    lines = clustered_lines(dump)
    probabilities = role_probabilities(lines)
    outcome = decide_local(dump)
    offsets = label_offsets(lines)
    spans = label_probabilities(lines)
    return {
        "doc": image.stem,
        "stage": outcome.stage,
        "store": store_of(lines, probabilities),
        "date": date_of(lines, probabilities),
        "total": outcome.total,
        "items": [
            {"name": i.name, "amount": i.amount, "discount": i.discount}
            for i in relabel(outcome.items, lines, offsets, spans)
        ],
        "fullText": dump["fullText"],
    }


def run(split: str, limit: int | None) -> list[TicketRun]:
    golden_dir = GOLDEN_DIR / SPLIT_DIRS[split]
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    images = _images(split, limit)
    runs = []
    exact_runs: list[dict] = []
    with ProcessPoolExecutor() as pool:
        for result in pool.map(_run_one, images):
            golden = json.loads((golden_dir / f"{result['doc']}.json").read_text())
            reference, verdict = best_reference(
                golden["receipt"], alternatives(SPLIT_DIRS[split], result["doc"])
            )
            result["truth"] = verdict.value
            if reference is None:
                exact_runs.append(result)
                continue
            expected = [round(float(item["amount"]), 2) for item in reference["items"]]
            result["edits"] = count_edits(
                [(i["amount"], i["discount"]) for i in result["items"]], expected
            )
            result["expected"] = expected
            exactness = receipt_exactness(
                result["store"],
                result["date"],
                result["total"],
                [
                    ExtractedName(i["name"], i["amount"], i["discount"])
                    for i in result["items"]
                ],
                {"receipt": reference},
            )
            result["wrong"] = exactness.wrong
            (OUTPUT_DIR / f"{split}_{result['doc']}.json").write_text(
                json.dumps(result, ensure_ascii=False)
            )
            exact_runs.append(result)
            runs.append(
                TicketRun(
                    name=f"{split}_{result['doc']}",
                    stage=result["stage"],
                    edits=result["edits"],
                    double_validated=bool(golden.get("transcript_agrees")),
                )
            )
    return runs, exact_runs


def report_exactness(results: list[dict]) -> None:
    """La métrique produit : un ticket ne compte que si tout est juste.

    Les tickets sans vérité — golden bancal qu'aucune chaîne indépendante ne
    tranche — sont comptés à part : les scorer mesurerait le golden."""
    judged = [result for result in results if "wrong" in result]
    unjudged = len(results) - len(judged)
    repaired = sum(1 for r in judged if r["truth"] == Verdict.REPAIRED.value)
    exact = sum(1 for result in judged if not result["wrong"])
    print(f"\n=== tickets parfaits : {exact}/{len(judged)} ({exact / len(judged):.1%})")
    print(f"  vérité : {len(judged) - repaired} golden, {repaired} réparés, "
          f"{unjudged} sans vérité (hors score)")
    causes: Counter[str] = Counter()
    for result in judged:
        for field in result["wrong"]:
            causes[field] += 1
    for field, count in causes.most_common():
        print(f"  {field:<10} faux sur {count:>4} tickets ({count / len(judged):.0%})")


def report(runs: list[TicketRun]) -> None:
    stages = [*VERIFIED_STAGES, CONFIRM]
    stats = {stage: StageStats() for stage in stages}
    for run_ in runs:
        stats[run_.stage].add(run_)
    total = len(runs)
    verified = sum(stats[stage].tickets for stage in VERIFIED_STAGES)
    false_verified = [r for stage in VERIFIED_STAGES for r in stats[stage].faulty]

    print(f"\n=== mode local, OCR Apple Vision ({total} tickets)")
    for stage in stages:
        stage_stats = stats[stage]
        if not stage_stats.tickets:
            continue
        mean = stage_stats.edits_total / stage_stats.tickets
        print(
            f"  {stage:<12}: {stage_stats.tickets:>4} "
            f"({stage_stats.tickets / total:.0%})  corr/ticket {mean:.2f}"
        )
    print(f"  vérifiés : {verified}/{total} ({verified / total:.1%})")
    print(f"  FAUX VÉRIFIÉS : {len(false_verified)}")
    for run_ in false_verified:
        print(f"    {run_.stage} {run_.name}: {run_.edits} corrections")


def main(argv: list[str]) -> int:
    split = "t1test"
    limit = None
    if "--split" in argv:
        split = argv[argv.index("--split") + 1]
    if "--limit" in argv:
        limit = int(argv[argv.index("--limit") + 1])
    runs, results = run(split, limit)
    report(runs)
    report_exactness(results)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
