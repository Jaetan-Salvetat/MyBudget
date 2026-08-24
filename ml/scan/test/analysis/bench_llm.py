"""Benchmark LLM vs règles : corrections par ticket sur vérité terrain."""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

from llm_structure import (
    amounts_in_text,
    ocr_lines_text,
    parse_llm_receipt,
    structure_with_llm,
)
from transcript_truth import extract_from_transcript

ROOT = Path(__file__).parent.parent
CACHE = ROOT / "results" / "llm_gemma3n_e2b"


def truth_backed_receipts() -> list[tuple[str, Path, Path]]:
    receipts = []
    for pattern, results_dir in [
        ("fr_genuine_*.json", ROOT / "results" / "device_fr"),
        ("fr_genuine_*.json", ROOT / "results" / "device_fr_big"),
    ]:
        for result in sorted(results_dir.glob(pattern)):
            name = result.name.replace(".jpg.json", "")
            doc_id = str(int(name.split("_")[-1]))
            txt = ROOT / "dataset_findit" / "T1-test" / "txt" / f"{doc_id}.txt"
            if txt.exists() and extract_from_transcript(txt).checksum_ok:
                receipts.append((name, result, txt))
    return receipts


def run(limit: int | None) -> None:
    CACHE.mkdir(exist_ok=True)
    receipts = truth_backed_receipts()
    if limit is not None:
        receipts = receipts[:limit]

    edits_total = 0
    items_total = 0
    dist: dict[int, int] = {}
    hallucinated = 0
    latencies = []
    failures = 0

    for index, (name, result, txt) in enumerate(receipts):
        cache_file = CACHE / f"{name}.json"
        lines_text = ocr_lines_text(result)
        if cache_file.exists():
            raw = json.loads(cache_file.read_text())
        else:
            start = time.time()
            try:
                raw = structure_with_llm(lines_text)
            except Exception as error:
                print(f"  FAIL {name}: {error}")
                failures += 1
                continue
            latencies.append(time.time() - start)
            cache_file.write_text(json.dumps(raw, ensure_ascii=False))

        truth = extract_from_transcript(txt)
        expected = [round(i.amount, 2) for i in truth.items]
        got, _total = parse_llm_receipt(raw)
        ocr_amounts = amounts_in_text(lines_text)

        remaining = list(expected)
        wrong = 0
        for amount, _discount in got:
            hit = next(
                (p for p in remaining if abs(p - amount) < 0.005), None
            )
            if hit is not None:
                remaining.remove(hit)
            else:
                wrong += 1
                if amount not in ocr_amounts:
                    hallucinated += 1
        edits = len(remaining) + wrong
        edits_total += edits
        items_total += len(expected)
        dist[min(edits, 5)] = dist.get(min(edits, 5), 0) + 1
        if (index + 1) % 10 == 0:
            print(f"  ...{index + 1}/{len(receipts)}")

    scored = sum(dist.values())
    print(f"\n=== LLM ({scored} tickets scorés, {failures} échecs techniques)")
    for k in sorted(dist):
        label = f"{k}+" if k == 5 else str(k)
        print(f"  {label} corrections : {dist[k]:>3} ({dist[k]/scored:.0%})")
    print(f"  moyenne : {edits_total/scored:.2f} correction/ticket")
    print(f"  articles à corriger : {edits_total}/{items_total} ({edits_total/items_total:.1%})")
    print(f"  montants hallucinés (absents du texte OCR) : {hallucinated}")
    if latencies:
        latencies.sort()
        print(
            f"  latence Mac : median {latencies[len(latencies)//2]:.1f}s, "
            f"p95 {latencies[int(len(latencies)*0.95)]:.1f}s"
        )


if __name__ == "__main__":
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else None
    run(limit)
