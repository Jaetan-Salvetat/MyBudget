"""Le mode local sur les photos de tickets prises au téléphone.

Le corpus FindIt est fait de scans à plat ; ces photos-là sont le vrai
terrain (papier froissé, ombres, perspective, ticket long). Pas de golden :
la mesure est l'étage atteint et le checksum, à croiser à la main avec le
texte OCR imprimé par `bench.scan_image`.

    uv run python -m bench.photos [<dossier>]
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from ocr.pipeline import dump_for
from paths import CORPUS_DIR, RESULTS_DIR
from reference.local_flow import clustered_lines, decide_local
from reference.structure import extract

PHOTOS_DIR = CORPUS_DIR / "photos_pixel"
OUTPUT_DIR = RESULTS_DIR / "photos_pixel"


def _run_one(image: Path) -> dict:
    dump = dump_for(image)
    receipt = extract(clustered_lines(dump))
    outcome = decide_local(dump)
    return {
        "image": image.name,
        "stage": outcome.stage,
        "total": outcome.total,
        "items": [[item.name, item.amount, item.discount] for item in outcome.items],
        "store": receipt.store,
        "date": receipt.date,
        "rulesTotal": receipt.total,
        "rulesItems": len(receipt.items),
        "fullText": dump["fullText"],
        "retryText": dump["ocrRetry"]["fullText"],
    }


def main(argv: list[str]) -> int:
    directory = Path(argv[0]) if argv else PHOTOS_DIR
    images = sorted(directory.glob("*.jpg"))
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    stages: Counter[str] = Counter()
    with ProcessPoolExecutor(max_workers=4) as pool:
        for result in pool.map(_run_one, images):
            (OUTPUT_DIR / f"{result['image']}.json").write_text(
                json.dumps(result, ensure_ascii=False)
            )
            stages[result["stage"]] += 1
            print(
                f"{result['image']:<32} {result['stage']:<12} "
                f"total {result['total']!s:>8}  {len(result['items']):>2} art."
                f"  enseigne {result['store']!r}  date {result['date']}"
            )
    print(f"\n=== {len(images)} photos")
    for stage, count in stages.most_common():
        print(f"  {stage:<12}: {count:>3} ({count / len(images):.0%})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
