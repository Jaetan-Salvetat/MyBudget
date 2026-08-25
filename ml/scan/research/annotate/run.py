"""Annote un corpus de tickets et en fait la base d'entraînement.

Pour chaque image : OCR local (page remise droite), lignes physiques,
annotation par le modèle, puis filtre — la sortie garde tout, acceptée ou
non, avec la raison du rejet. Le fichier par ticket sert de cache : relancer
ne refait que ce qui manque.

    OPENROUTER_API_KEY=... uv run python -m annotate.run <dossier>... [--workers N]
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from annotate.client import AnnotationError, annotate, preview_data_url
from annotate.prompt import instructions, numbered_lines
from annotate.validate import rejection_reason
from ocr.pipeline import dump_for
from paths import DATA_DIR
from reference.lines import PhysicalLine
from reference.local_flow import clustered_lines

ANNOTATIONS_DIR = DATA_DIR / "annotations"
DEFAULT_WORKERS = 8
ATTEMPTS = 3


def _serialize(lines: list[PhysicalLine]) -> list[dict]:
    """Les lignes telles que le modèle les recevra à l'inférence : texte et
    géométrie. Le dataset se reconstruit sans refaire l'OCR."""
    return [
        {
            "text": line.text,
            "words": [
                {
                    "text": word.text,
                    "box": [word.left, word.top, word.right, word.bottom],
                    "confidence": word.confidence,
                }
                for word in line.words
            ],
        }
        for line in lines
    ]


def _annotate_with_retry(prompt: str, lines_text: str, image_url: str) -> dict:
    last: AnnotationError | None = None
    for _attempt in range(ATTEMPTS):
        try:
            return annotate(prompt, lines_text, image_url)
        except AnnotationError as error:
            last = error
    raise last if last else AnnotationError("échec sans cause")


def process(image: Path, output: Path) -> str:
    if output.exists():
        return json.loads(output.read_text()).get("reason") or "accepté"

    dump = dump_for(image, with_retry=False)
    lines = clustered_lines(dump)
    if not lines:
        record = {"image": image.name, "reason": "aucune ligne lue"}
    else:
        annotation = _annotate_with_retry(
            instructions(),
            numbered_lines(lines),
            preview_data_url(image, dump.get("rotationApplied", 0)),
        )
        record = {
            "image": image.name,
            "source": image.parent.name,
            "rotation": dump.get("rotationApplied", 0),
            "lines": _serialize(lines),
            "annotation": annotation,
            "reason": rejection_reason(annotation, lines),
        }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(record, ensure_ascii=False))
    return record.get("reason") or "accepté"


def _safe_process(image: Path, output: Path) -> str:
    try:
        return process(image, output)
    except (AnnotationError, OSError, ValueError, KeyError) as error:
        print(f"  ÉCHEC {image.name} : {error}", file=sys.stderr)
        return "échec technique"


def _corpus_name(directory: Path) -> str:
    """Nom du corpus. Les jeux FindIt rangent leurs images sous `<split>/img`
    : c'est le split qui identifie le corpus, pas le dossier feuille."""
    return directory.parent.name if directory.name == "img" else directory.name


def main(argv: list[str]) -> int:
    workers = DEFAULT_WORKERS
    if "--workers" in argv:
        workers = int(argv[argv.index("--workers") + 1])
    directories = [Path(a) for a in argv if not a.startswith("--") and Path(a).is_dir()]
    if not directories:
        print(__doc__)
        return 1

    jobs = [
        (image, ANNOTATIONS_DIR / _corpus_name(directory) / f"{image.stem}.json")
        for directory in directories
        for image in sorted(directory.glob("*.jpg")) + sorted(directory.glob("*.png"))
    ]
    outcomes: Counter[str] = Counter()
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as pool:
        for reason in pool.map(lambda job: _safe_process(*job), jobs):
            outcomes["accepté" if reason == "accepté" else "rejeté"] += 1
            done += 1
            if done % 10 == 0:
                print(f"  {done}/{len(jobs)}", flush=True)

    accepted = outcomes["accepté"]
    print(f"\n=== {len(jobs)} tickets annotés")
    print(f"  acceptés : {accepted} ({accepted / max(len(jobs), 1):.0%})")
    print(f"  rejetés  : {outcomes['rejeté']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
