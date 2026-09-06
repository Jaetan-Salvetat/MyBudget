"""Reconstruit les sélections d'images dérivées des datasets bruts.

Reproduit exactement les corpus utilisés par les benchmarks : mêmes
tickets, mêmes noms de fichiers, pour que les caches et résultats restent
comparables d'une machine à l'autre.
"""

from __future__ import annotations

import re
import shutil

from paths import CORPUS_DIR, FINDIT_DIR

GENUINE_SMALL = 50
GENUINE_BIG_END = 300
FORGED_COUNT = 15


def rebuild_findit_selections() -> None:
    gt = (FINDIT_DIR / "T1-Test-GT.xml").read_text()
    docs = re.findall(r'<doc id="(\d+)" modified="(\d)"', gt)
    img_dir = FINDIT_DIR / "T1-test" / "img"
    genuine = [d for d, m in docs if m == "0" and (img_dir / f"{d}.jpg").exists()]
    forged = [d for d, m in docs if m == "1" and (img_dir / f"{d}.jpg").exists()]

    small = CORPUS_DIR / "selection_fr"
    big = CORPUS_DIR / "selection_fr_big"
    small.mkdir(exist_ok=True)
    big.mkdir(exist_ok=True)
    for doc_id in genuine[:GENUINE_SMALL]:
        shutil.copy(img_dir / f"{doc_id}.jpg", small / f"fr_genuine_{int(doc_id):04d}.jpg")
    for doc_id in forged[:FORGED_COUNT]:
        shutil.copy(img_dir / f"{doc_id}.jpg", small / f"fr_forged_{int(doc_id):04d}.jpg")
    for doc_id in genuine[GENUINE_SMALL:GENUINE_BIG_END]:
        shutil.copy(img_dir / f"{doc_id}.jpg", big / f"fr_genuine_{int(doc_id):04d}.jpg")
    print(f"selection_fr: {len(list(small.glob('*.jpg')))}, "
        f"selection_fr_big: {len(list(big.glob('*.jpg')))}")


if __name__ == "__main__":
    rebuild_findit_selections()
