"""Benchmark VLM cloud (Gemini Flash batch via OpenRouter) : image → JSON.

Mesure le plafond « un VLM comprend le ticket » avec un modèle multimodal
fort, sur les mêmes 250 tickets et la même métrique que les règles et le LLM
local. La clé API est lue dans OPENROUTER_API_KEY, jamais écrite sur disque.
"""

from __future__ import annotations

import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from llm.gemini import CALL_ERRORS, call_gemini
from llm.structure import parse_llm_receipt
from paths import CORPUS_DIR, RESULTS_DIR
from truth.selection import truth_backed_receipts
from truth.transcript import extract_from_transcript

CACHE = RESULTS_DIR / "llm_gemini37_flash"


def _image_path(name: str) -> Path:
    for directory in [CORPUS_DIR / "selection_fr", CORPUS_DIR / "selection_fr_big"]:
        candidate = directory / f"{name}.jpg"
        if candidate.exists():
            return candidate
    raise FileNotFoundError(name)


def _process(entry, api_key: str) -> str | None:
    name, _result, _txt = entry
    cache_file = CACHE / f"{name}.json"
    if cache_file.exists():
        return None
    try:
        raw = call_gemini(_image_path(name), api_key)
    except CALL_ERRORS as error:
        return f"FAIL {name}: {error}"
    cache_file.write_text(json.dumps(raw, ensure_ascii=False))
    return None


def score() -> None:
    edits_total = 0
    items_total = 0
    dist: dict[int, int] = {}
    disagreements = []
    for name, _result, txt in truth_backed_receipts():
        cache_file = CACHE / f"{name}.json"
        if not cache_file.exists():
            continue
        truth = extract_from_transcript(txt)
        expected = [round(i.amount, 2) for i in truth.items]
        got, _total = parse_llm_receipt(json.loads(cache_file.read_text()))
        remaining = list(expected)
        wrong = []
        for amount, _discount in got:
            hit = next((p for p in remaining if abs(p - amount) < 0.005), None)
            if hit is not None:
                remaining.remove(hit)
            else:
                wrong.append(amount)
        edits = len(remaining) + len(wrong)
        edits_total += edits
        items_total += len(expected)
        dist[min(edits, 5)] = dist.get(min(edits, 5), 0) + 1
        if edits:
            disagreements.append((name, wrong, remaining))

    scored = sum(dist.values())
    print(f"\n=== Gemini 3.7 Flash sur IMAGES ({scored} tickets)")
    for k in sorted(dist):
        label = f"{k}+" if k == 5 else str(k)
        print(f"  {label} corrections : {dist[k]:>3} ({dist[k]/scored:.0%})")
    print(f"  moyenne : {edits_total/scored:.2f} correction/ticket")
    print(
        f"  articles à corriger : {edits_total}/{items_total} "
        f"({edits_total/items_total:.1%})"
    )
    print(f"\n{len(disagreements)} tickets en désaccord avec la vérité terrain :")
    for name, wrong, missed in disagreements[:30]:
        print(f"  {name}: gemini_en_plus={wrong} gemini_manque={missed}")


def main() -> None:
    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        print("OPENROUTER_API_KEY manquante")
        sys.exit(1)
    CACHE.mkdir(exist_ok=True)
    receipts = truth_backed_receipts()
    if len(sys.argv) > 1:
        receipts = receipts[: int(sys.argv[1])]
    start = time.time()
    with ThreadPoolExecutor(max_workers=8) as pool:
        for error in pool.map(lambda e: _process(e, api_key), receipts):
            if error:
                print(error)
    print(f"batch terminé en {time.time() - start:.0f}s")
    score()


if __name__ == "__main__":
    main()
