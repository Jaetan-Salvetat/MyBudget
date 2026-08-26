"""Annote un corpus de tickets et en fait la base d'entraînement.

Pour chaque image : OCR local (page remise droite), lignes physiques,
annotation par le modèle. La sortie garde tout, acceptée ou non — c'est le
chargeur qui rejoue le filtre, pas ce script. Le fichier par ticket sert de
cache : relancer ne refait que ce qui manque.

    OPENROUTER_API_KEY=... uv run python -m annotate.run <dossier>... [--workers N]

`--stale` ré-annote ce que le modèle ou le prompt courants n'ont pas produit,
et rien d'autre : c'est un appel payant par ticket, donc il ne touche que ce
qui le mérite. Les tickets annotés avant que la provenance n'existe comptent
comme périmés — on ne sait pas ce qui les a produits.
"""

from __future__ import annotations

import sys
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime
from pathlib import Path

from annotate import record
from annotate.client import MODEL, AnnotationError, annotate, preview_data_url
from annotate.prompt import fingerprint, instructions, numbered_lines, positional
from annotate.validate import rejection
from ocr.pipeline import dump_for
from paths import ANNOTATIONS_DIR
from reference.local_flow import clustered_lines

DEFAULT_WORKERS = 8
ATTEMPTS = 3
MALFORMED = "réponse hors contrat"


def provenance() -> dict:
    return {
        "model": MODEL,
        "prompt": fingerprint(),
        "date": datetime.now(UTC).date().isoformat(),
    }


def _annotate_with_retry(prompt: str, lines_text: str, image_url: str) -> dict:
    last: AnnotationError | None = None
    for _attempt in range(ATTEMPTS):
        try:
            return annotate(prompt, lines_text, image_url)
        except AnnotationError as error:
            last = error
    raise last if last else AnnotationError("échec sans cause")


def _needs_work(output: Path, stale_only: bool, current: dict) -> bool:
    if not output.exists():
        return True
    return stale_only and record.is_stale(record.read(output), current)


def process(image: Path, output: Path, stale_only: bool = False) -> str:
    current = provenance()
    if not _needs_work(output, stale_only, current):
        stored = record.read(output)
        verdict = rejection(stored.entries, stored.lines)
        return str(verdict) if verdict else "accepté"

    dump = dump_for(image, with_retry=False)
    lines = clustered_lines(dump)
    entries: list[dict] | None = []
    store = date_read = None
    if lines:
        annotation = _annotate_with_retry(
            instructions(),
            numbered_lines(lines),
            preview_data_url(image, dump.get("rotationApplied", 0)),
        )
        entries = positional(annotation, len(lines))
        store, date_read = annotation.get("store"), annotation.get("date")
        if entries is None:
            return MALFORMED

    record.write(
        output,
        image=image.name,
        lines=lines,
        entries=entries,
        store=store,
        date=date_read,
        provenance=current,
    )
    verdict = rejection(entries, lines)
    return str(verdict) if verdict else "accepté"


def _safe_process(image: Path, output: Path, stale_only: bool) -> str:
    try:
        return process(image, output, stale_only)
    except (AnnotationError, OSError, ValueError, KeyError) as error:
        print(f"  ÉCHEC {image.name} : {error}", file=sys.stderr)
        return "échec technique"


def corpus_name(directory: Path) -> str:
    """Nom du corpus. Les jeux FindIt rangent leurs images sous `<split>/img`
    : c'est le split qui identifie le corpus, pas le dossier feuille."""
    return directory.parent.name if directory.name == "img" else directory.name


def main(argv: list[str]) -> int:
    workers = DEFAULT_WORKERS
    stale_only = "--stale" in argv
    if "--workers" in argv:
        workers = int(argv[argv.index("--workers") + 1])
    directories = [Path(a) for a in argv if not a.startswith("--") and Path(a).is_dir()]
    if not directories:
        print(__doc__)
        return 1

    jobs = [
        (image, ANNOTATIONS_DIR / corpus_name(directory) / f"{image.stem}.json")
        for directory in directories
        for image in sorted(directory.glob("*.jpg")) + sorted(directory.glob("*.png"))
    ]
    outcomes: Counter[str] = Counter()
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as pool:
        for reason in pool.map(lambda job: _safe_process(*job, stale_only), jobs):
            outcomes[reason] += 1
            done += 1
            if done % 10 == 0:
                print(f"  {done}/{len(jobs)}", flush=True)

    accepted = outcomes["accepté"]
    print(f"\n=== {len(jobs)} tickets annotés")
    print(f"  acceptés : {accepted} ({accepted / max(len(jobs), 1):.0%})")
    for reason, count in outcomes.most_common():
        if reason != "accepté":
            print(f"  {count:5}  {reason}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
