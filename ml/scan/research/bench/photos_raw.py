"""La métrique produit sur photos réelles, **depuis l'OCR brut**.

`bench.held_out` part des lignes stockées dans les annotations — donc déjà
regroupées. Il juge la structuration et ne peut rien dire du regroupement
lui-même : `cluster_lines` n'y est jamais appelé. Tout ce qui touche à la
géométrie des lignes lui est invisible.

Ce bench-ci repart des mots : le dump OCR de la photo, déskew, regroupement,
puis le flow local complet. La vérité reste l'annotation, qui porte le reçu
(enseigne, date, total, articles nommés) indépendamment de tout découpage en
lignes.

    uv run python -m bench.photos_raw [--limit=N]
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

from annotate.dataset import load
from bench.exactness import SILENT, ExtractedName, receipt_exactness
from paths import ANNOTATIONS_DIR, RESULTS_DIR
from reference.labels_ml import label_offsets, relabel
from reference.local_flow import VERIFIED_SOURCES, decide_local
from reference.spans_ml import label_probabilities
from truth.references import receipt_from_annotation


def raw_dumps() -> dict[str, Path]:
    """Le dump OCR de chaque image, indexé par nom d'image."""
    dumps: dict[str, Path] = {}
    for path in (RESULTS_DIR / "ocr_cache").glob("*.json"):
        try:
            payload = json.loads(path.read_text())
        except (OSError, ValueError):
            continue
        image = payload.get("image")
        if image and "blocks" in payload:
            dumps.setdefault(Path(image).stem, path)
    return dumps


def run(limit: int | None) -> list[dict]:
    dumps = raw_dumps()
    scored = []
    for receipt in load(held_out=True):
        dump_path = dumps.get(Path(receipt.name).stem)
        if dump_path is None:
            continue
        truth_path = (
            ANNOTATIONS_DIR / receipt.corpus / f"{Path(receipt.name).stem}.json"
        )
        if not truth_path.exists():
            continue
        truth = receipt_from_annotation(json.loads(truth_path.read_text()))
        if truth is None or not truth["items"]:
            continue

        outcome = decide_local(json.loads(dump_path.read_text()))
        verified = outcome.source in VERIFIED_SOURCES
        named = relabel(
            outcome.items,
            outcome.lines,
            label_offsets(outcome.lines),
            label_probabilities(outcome.lines),
        )
        exactness = receipt_exactness(
            None,
            None,
            outcome.total,
            [ExtractedName(i.name, i.amount, i.discount) for i in named],
            {"receipt": truth},
        )
        scored.append(
            {
                "name": receipt.name,
                "verified": verified,
                "wrong": [w for w in exactness.wrong if w not in ("enseigne", "date")],
                "silent": [k for k in exactness.silent if k in SILENT],
            }
        )
        if limit and len(scored) >= limit:
            break
    return scored


def report(scored: list[dict]) -> None:
    total = len(scored)
    if not total:
        print("aucun ticket à juger")
        return
    verified = [row for row in scored if row["verified"]]
    exact = [row for row in verified if not row["wrong"]]
    silent = [row for row in verified if row["silent"]]
    print(f"\n=== {total} photos, rejouées depuis l'OCR brut")
    print(f"  vérifiés         : {len(verified)} ({len(verified) / total:.1%})")
    print(f"  tickets parfaits : {len(exact)} ({len(exact) / total:.1%})")
    postes: Counter[str] = Counter()
    for row in verified:
        for poste in row["wrong"]:
            postes[poste] += 1
    for poste, count in postes.most_common():
        print(f"    {poste:<18}{count:>4}")
    print(f"  erreurs silencieuses : {len(silent)}")


def main(argv: list[str]) -> int:
    limit = next(
        (int(a.split("=", 1)[1]) for a in argv if a.startswith("--limit=")), None
    )
    report(run(limit))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
