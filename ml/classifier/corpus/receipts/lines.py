import json
import random
from pathlib import Path

from corpus.receipts.style import receipt_line
from serving.normalize import normalize_receipt_line

LINES_DIR = Path(__file__).resolve().parent / "lines"
LINE_VARIANTS = 4
LINE_ABBREVIATION_RATE = 0.35
KEY_PREFIX = "lines:"


def read_lines(directory: Path = LINES_DIR) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for path in sorted(directory.glob("*.json")):
        document = json.loads(path.read_text(encoding="utf-8"))
        slug = document["slug"]
        if slug != path.stem:
            raise ValueError(f"{path.name} porte le slug {slug}")
        out[slug] = list(document["lines"])
    return out


def generated_lines(
    rng: random.Random, directory: Path = LINES_DIR, variants: int = LINE_VARIANTS
) -> list[tuple[str, str, str]]:
    out: list[tuple[str, str, str]] = []
    for slug, entries in read_lines(directory).items():
        for entry in entries:
            key = f"{KEY_PREFIX}{slug}:{entry}"
            out.append((key, normalize_receipt_line(entry), slug))
            for _ in range(variants - 1):
                styled = receipt_line(entry, rng, abbreviation_rate=LINE_ABBREVIATION_RATE)
                out.append((key, normalize_receipt_line(styled), slug))
    return out
