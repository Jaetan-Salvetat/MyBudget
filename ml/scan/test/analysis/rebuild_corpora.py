"""Reconstruit les sélections d'images dérivées des datasets bruts.

Reproduit exactement les corpus utilisés par les benchmarks : mêmes
tickets, mêmes noms de fichiers, pour que les caches et résultats restent
comparables d'une machine à l'autre.
"""

from __future__ import annotations

import re
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).parent.parent
GENUINE_SMALL = 50
GENUINE_BIG_END = 300
FORGED_COUNT = 15
SRD_MIN_LONG_SIDE = 1200
SRD_TOP_UP_TO = 40


def rebuild_findit_selections() -> None:
    gt = (ROOT / "dataset_findit" / "T1-Test-GT.xml").read_text()
    docs = re.findall(r'<doc id="(\d+)" modified="(\d)"', gt)
    img_dir = ROOT / "dataset_findit" / "T1-test" / "img"
    genuine = [d for d, m in docs if m == "0" and (img_dir / f"{d}.jpg").exists()]
    forged = [d for d, m in docs if m == "1" and (img_dir / f"{d}.jpg").exists()]

    small = ROOT / "corpus_fr"
    big = ROOT / "corpus_fr_big"
    small.mkdir(exist_ok=True)
    big.mkdir(exist_ok=True)
    for doc_id in genuine[:GENUINE_SMALL]:
        shutil.copy(img_dir / f"{doc_id}.jpg", small / f"fr_genuine_{int(doc_id):04d}.jpg")
    for doc_id in forged[:FORGED_COUNT]:
        shutil.copy(img_dir / f"{doc_id}.jpg", small / f"fr_forged_{int(doc_id):04d}.jpg")
    for doc_id in genuine[GENUINE_SMALL:GENUINE_BIG_END]:
        shutil.copy(img_dir / f"{doc_id}.jpg", big / f"fr_genuine_{int(doc_id):04d}.jpg")
    print(f"corpus_fr: {len(list(small.glob('*.jpg')))}, corpus_fr_big: {len(list(big.glob('*.jpg')))}")


def rebuild_srd_selection(srd_dir: Path = Path("/tmp/srd")) -> None:
    out = ROOT / "corpus_web"
    out.mkdir(exist_ok=True)
    sized = []
    for image in sorted(srd_dir.glob("*.jpg")):
        width, height = Image.open(image).size
        sized.append((max(width, height), image))
    sized.sort(reverse=True)
    picked = [img for side, img in sized if side >= SRD_MIN_LONG_SIDE]
    for _side, image in sized:
        if len(picked) >= SRD_TOP_UP_TO:
            break
        if image not in picked:
            picked.append(image)
    for image in picked[:SRD_TOP_UP_TO]:
        shutil.copy(image, out / f"srd_{image.name}")
    print(f"corpus_web (SRD): {len(list(out.glob('srd_*.jpg')))}")


if __name__ == "__main__":
    rebuild_findit_selections()
    if Path("/tmp/srd").exists():
        rebuild_srd_selection()
    else:
        print("SRD absent de /tmp/srd — lancer fetch_datasets.sh d'abord")
