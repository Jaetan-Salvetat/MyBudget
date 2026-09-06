"""Tickets FindIt dont la transcription fournit une vérité terrain fiable.

Un ticket n'est retenu que si sa transcription passe son propre checksum :
mesurer contre une vérité incertaine ne mesure rien.
"""

from __future__ import annotations

from pathlib import Path

from paths import FINDIT_DIR, RESULTS_DIR
from truth.transcript import extract_from_transcript


def truth_backed_receipts() -> list[tuple[str, Path, Path]]:
    receipts = []
    for pattern, results_dir in [
        ("fr_genuine_*.json", RESULTS_DIR / "device_fr"),
        ("fr_genuine_*.json", RESULTS_DIR / "device_fr_big"),
    ]:
        for result in sorted(results_dir.glob(pattern)):
            name = result.name.replace(".jpg.json", "")
            doc_id = str(int(name.split("_")[-1]))
            txt = FINDIT_DIR / "T1-test" / "txt" / f"{doc_id}.txt"
            if txt.exists() and extract_from_transcript(txt).checksum_ok:
                receipts.append((name, result, txt))
    return receipts
