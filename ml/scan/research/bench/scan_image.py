"""Le flow local complet sur une image du disque, étage par étage.

Le bench principal rejoue des dumps device ; ici l'OCR tourne sur le Mac
(Apple Vision, `ocr/`) pour diagnostiquer un ticket qu'aucun run device ne
couvre. Sortie : les lignes physiques, ce que chaque étage a lu, et l'étage
qui a tranché.

    uv run python -m bench.scan_image <image>... [--lines] [--json <dir>]
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from ocr.pipeline import dump_for
from reference.decode_constrained import extract_constrained
from reference.local_flow import (
    clustered_lines,
    decide_local,
    fused_rescue,
)
from reference.structure import ExtractedReceipt, extract, merge_price_fragments
from reference.structure_ml import extract_ml

PASS_NAMES = ("passe 1", "retry")


def _summary(receipt: ExtractedReceipt | None) -> str:
    if receipt is None:
        return "aucune sortie"
    flag = "checksum OK" if receipt.checksum_ok else "checksum KO"
    return (
        f"{len(receipt.items)} articles, somme {receipt.items_sum:.2f}, "
        f"total {receipt.total}, sous-total {receipt.subtotal}, "
        f"paiement {receipt.payment} — {flag}"
    )


def _stage_report(passes: list[list]) -> list[str]:
    report = []
    for name, lines in zip(PASS_NAMES, passes):
        merged = [merge_price_fragments(line) for line in lines]
        report.append(f"  règles     [{name}] {_summary(extract(lines))}")
        report.append(f"  classifieur[{name}] {_summary(extract_ml(merged))}")
        report.append(f"  décodeur   [{name}] {_summary(extract_constrained(merged))}")
    if len(passes) == 2:
        report.append(f"  fusion              {_summary(fused_rescue(passes))}")
    return report


def _lines_report(lines: list) -> list[str]:
    return [f"  {line.top:7.1f}  {line.text}" for line in lines]


def report(image: Path, show_lines: bool, dumps_dir: Path | None) -> None:
    dump = dump_for(image)
    if dumps_dir is not None:
        dumps_dir.mkdir(parents=True, exist_ok=True)
        (dumps_dir / f"{image.name}.json").write_text(json.dumps(dump))

    passes = [clustered_lines(dump), clustered_lines(dump["ocrRetry"])]
    receipt = extract(passes[0])
    outcome = decide_local(dump)

    print(f"\n=== {image.name} ({dump['imageWidth']}x{dump['imageHeight']}) ===")
    print(f"  enseigne {receipt.store!r}  date {receipt.date!r}")
    print("\n".join(_stage_report(passes)))
    print(f"  → étage retenu : {outcome.stage}, total {outcome.total}")
    for amount, discount in outcome.items:
        print(f"      {amount:8.2f}" + (f"  remise {discount:.2f}" if discount else ""))
    if show_lines:
        for name, lines in zip(PASS_NAMES, passes):
            print(f"  --- lignes {name} ---")
            print("\n".join(_lines_report(lines)))


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
