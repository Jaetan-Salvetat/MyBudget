"""Construit le golden dataset : annotations de référence des tickets FindIt.

Chaque ticket T1 est annoté par Gemini 3.7 Flash depuis l'image, puis
recoupé quand c'est possible avec l'extraction depuis la transcription texte
(chaîne indépendante). Les JSON produits vivent dans le repo : tous les
benchmarks et entraînements futurs se font dessus sans nouvel appel payant.
"""

from __future__ import annotations

import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from pathlib import Path

from llm.gemini import MODEL, call_gemini
from llm.structure import parse_llm_receipt
from paths import FINDIT_DIR, GOLDEN_DIR, RESULTS_DIR
from truth.transcript import extract_from_transcript

GOLDEN = GOLDEN_DIR
LEGACY_CACHE = RESULTS_DIR / "llm_gemini37_flash"
SPLITS = ["T1-test", "T1-train"]


def _golden_path(split: str, doc_id: str) -> Path:
    return GOLDEN / split / f"{doc_id}.json"


def _legacy_annotation(split: str, doc_id: str) -> dict | None:
    if split != "T1-test":
        return None
    legacy = LEGACY_CACHE / f"fr_genuine_{int(doc_id):04d}.json"
    if legacy.exists():
        return json.loads(legacy.read_text())
    return None


def _cross_check(split: str, doc_id: str, annotation: dict) -> bool | None:
    txt = FINDIT_DIR / split / "txt" / f"{doc_id}.txt"
    if not txt.exists():
        return None
    truth = extract_from_transcript(txt)
    if not truth.checksum_ok:
        return None
    expected = sorted(round(i.amount, 2) for i in truth.items)
    got, _total = parse_llm_receipt(annotation)
    return expected == sorted(amount for amount, _discount in got)


def _annotate_one(entry: tuple[str, str], api_key: str) -> str | None:
    split, doc_id = entry
    target = _golden_path(split, doc_id)
    if target.exists():
        return None
    annotation = _legacy_annotation(split, doc_id)
    provenance = "cache"
    if annotation is None:
        image = FINDIT_DIR / split / "img" / f"{doc_id}.jpg"
        try:
            annotation = call_gemini(image, api_key)
        except Exception as error:
            return f"FAIL {split}/{doc_id}: {error}"
        provenance = "api"
    record = {
        "source": f"raw/findit/{split}/img/{doc_id}.jpg",
        "annotator": MODEL,
        "annotated_on": date.today().isoformat(),
        "provenance": provenance,
        "transcript_agrees": _cross_check(split, doc_id, annotation),
        "receipt": annotation,
    }
    target.write_text(json.dumps(record, ensure_ascii=False, indent=1))
    return None


def main() -> None:
    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        print("OPENROUTER_API_KEY manquante")
        sys.exit(1)

    entries: list[tuple[str, str]] = []
    for split in SPLITS:
        (GOLDEN / split).mkdir(parents=True, exist_ok=True)
        for image in sorted((FINDIT_DIR / split / "img").glob("*.jpg")):
            entries.append((split, image.stem))
    if len(sys.argv) > 1:
        entries = entries[: int(sys.argv[1])]

    start = time.time()
    failures = 0
    with ThreadPoolExecutor(max_workers=8) as pool:
        for error in pool.map(lambda e: _annotate_one(e, api_key), entries):
            if error:
                failures += 1
                print(error)
    print(f"annotation terminée en {time.time() - start:.0f}s, {failures} échecs")

    agree = disagree = unchecked = 0
    for split in SPLITS:
        for f in (GOLDEN / split).glob("*.json"):
            flag = json.loads(f.read_text())["transcript_agrees"]
            if flag is True:
                agree += 1
            elif flag is False:
                disagree += 1
            else:
                unchecked += 1
    total = agree + disagree + unchecked
    print(f"golden: {total} tickets")
    print(f"  double-validés (Gemini = transcription) : {agree}")
    print(f"  désaccords à auditer                    : {disagree}")
    print(f"  source unique Gemini (transcription HS) : {unchecked}")


if __name__ == "__main__":
    main()
