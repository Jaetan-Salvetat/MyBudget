"""Génère le corpus synthétique : images + ground truth JSON."""

from __future__ import annotations

import json
import random
from pathlib import Path

from receipt_content import ReceiptGenerator, render_lines
from receipt_render import render_paper, save_jpeg, simulate_photo

LEVELS = ["clean", "photo", "hard"]
RECEIPTS_PER_LEVEL = 40
SEED = 42


def main() -> None:
    root = Path(__file__).parent.parent
    images_dir = root / "corpus_synthetic"
    truth_dir = root / "corpus_synthetic" / "truth"
    images_dir.mkdir(exist_ok=True)
    truth_dir.mkdir(exist_ok=True)

    rng = random.Random(SEED)
    generator = ReceiptGenerator(rng=rng)

    for level in LEVELS:
        for index in range(RECEIPTS_PER_LEVEL):
            receipt = generator.generate()
            name = f"syn_{level}_{index:02d}"
            lines = render_lines(receipt, rng)
            paper = render_paper(lines, rng)
            image = simulate_photo(paper, level, rng)
            save_jpeg(image, images_dir / f"{name}.jpg")
            truth = receipt.ground_truth()
            truth["level"] = level
            (truth_dir / f"{name}.json").write_text(
                json.dumps(truth, ensure_ascii=False, indent=2)
            )
            print(f"{name}: {len(receipt.items)} items, total {receipt.total:.2f}")


if __name__ == "__main__":
    main()
