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
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from bench.flow import StageStats, TicketRun, count_edits
from ocr.pipeline import dump_for
from paths import FINDIT_DIR, GOLDEN_DIR, RESULTS_DIR
from reference.local_flow import CONFIRM, VERIFIED_STAGES, decide_local

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
    outcome = decide_local(dump)
    return {
        "doc": image.stem,
        "stage": outcome.stage,
        "total": outcome.total,
        "items": [list(item) for item in outcome.items],
        "fullText": dump["fullText"],
    }


def run(split: str, limit: int | None) -> list[TicketRun]:
    golden_dir = GOLDEN_DIR / SPLIT_DIRS[split]
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    images = _images(split, limit)
    runs = []
    with ProcessPoolExecutor() as pool:
        for result in pool.map(_run_one, images):
            golden = json.loads((golden_dir / f"{result['doc']}.json").read_text())
            expected = [
                round(float(item["amount"]), 2)
                for item in golden["receipt"]["items"]
            ]
            got = [(amount, discount) for amount, discount in result["items"]]
            result["edits"] = count_edits(got, expected)
            result["expected"] = expected
            (OUTPUT_DIR / f"{split}_{result['doc']}.json").write_text(
                json.dumps(result, ensure_ascii=False)
            )
            runs.append(
                TicketRun(
                    name=f"{split}_{result['doc']}",
                    stage=result["stage"],
                    edits=result["edits"],
                    double_validated=bool(golden.get("transcript_agrees")),
                )
            )
    return runs


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
    report(run(split, limit))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
