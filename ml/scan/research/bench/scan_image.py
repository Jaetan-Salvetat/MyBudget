"""Le flow local sur une image du disque, lecture par lecture.

Le bench principal rejoue des dumps device ; ici l'OCR tourne sur le Mac
(Apple Vision, `ocr/`) pour diagnostiquer un ticket qu'aucun run device ne
couvre. Sortie : les lignes physiques, ce que chaque lecture de l'image
prouve, et celle qui a tranché.

    uv run python -m bench.scan_image <image>... [--lines] [--json <dir>]
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from ocr.pipeline import dump_for
from reference.header_ml import date_of, role_probabilities, store_of
from reference.local_flow import decide_local, read, sources
from reference.structure import ExtractedReceipt


def _summary(receipt: ExtractedReceipt | None) -> str:
    if receipt is None:
        return "aucune sortie"
    flag = "checksum OK" if receipt.checksum_ok else "checksum KO"
    return (
        f"{len(receipt.items)} articles, somme {receipt.items_sum:.2f}, "
        f"total {receipt.total}, sous-total {receipt.subtotal}, "
        f"paiement {receipt.payment} — {flag}"
    )


def _stage_report(dump: dict) -> list[str]:
    """Ce que chaque lecture prouve, indépendamment — le flow s'arrête à la
    première, ce rapport les montre toutes."""
    return [f"  {source.name:<8} {_summary(read(source))}" for source in sources(dump)]


def _lines_report(lines: list) -> list[str]:
    return [f"  {line.top:7.1f}  {line.text}" for line in lines]


def report(image: Path, show_lines: bool, dumps_dir: Path | None) -> None:
    dump = dump_for(image)
    if dumps_dir is not None:
        dumps_dir.mkdir(parents=True, exist_ok=True)
        (dumps_dir / f"{image.name}.json").write_text(json.dumps(dump))

    outcome = decide_local(dump)
    roles = role_probabilities(outcome.lines)

    print(f"\n=== {image.name} ({dump['imageWidth']}x{dump['imageHeight']}) ===")
    print(
        f"  enseigne {store_of(outcome.lines, roles)!r}  "
        f"date {date_of(outcome.lines, roles)!r}"
    )
    print("\n".join(_stage_report(dump)))
    print(f"  → lecture retenue : {outcome.source}, total {outcome.total}")
    for item in outcome.items:
        print(
            f"      {item.amount:8.2f}  {item.name!r}"
            + (f"  remise {item.discount:.2f}" if item.discount else "")
        )
    if show_lines:
        print("  --- lignes retenues ---")
        print("\n".join(_lines_report(outcome.lines)))


def main(argv: list[str]) -> int:
    show_lines = "--lines" in argv
    dumps_dir = None
    if "--json" in argv:
        dumps_dir = Path(argv[argv.index("--json") + 1])
        argv = [a for a in argv if a != str(dumps_dir)]
    images = [Path(a) for a in argv if not a.startswith("--")]
    if not images:
        print(__doc__)
        return 1
    for image in images:
        report(image, show_lines, dumps_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
