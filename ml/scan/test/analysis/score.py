"""Score le pipeline OCR + structuration contre le ground truth synthétique.

Métriques article : un article extrait matche un article attendu si son
montant est identique au centime (le nom sert au diagnostic, pas au score :
c'est BERT qui le consommera, et il tolère du bruit).
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from structure import ExtractedReceipt, extract_from_result

ROOT = Path(__file__).parent.parent


@dataclass
class ReceiptScore:
    name: str
    level: str
    expected_items: int
    matched_items: int
    extracted_items: int
    discounts_expected: int
    discounts_matched: int
    total_ok: bool
    checksum_ok: bool
    date_ok: bool


def score_receipt(result_path: Path, truth_path: Path) -> ReceiptScore:
    truth = json.loads(truth_path.read_text())
    extracted = extract_from_result(result_path)

    expected = [(item["amount"], item["discount"]) for item in truth["items"]]
    remaining = list(expected)
    matched = 0
    discounts_matched = 0
    for item in extracted.items:
        key = next(
            (
                pair
                for pair in remaining
                if abs(pair[0] - item.amount) < 0.005
            ),
            None,
        )
        if key is None:
            continue
        remaining.remove(key)
        matched += 1
        if abs(key[1] - item.discount) < 0.005 and key[1] > 0:
            discounts_matched += 1

    total_ok = (
        extracted.total is not None
        and abs(extracted.total - truth["total"]) < 0.005
    )
    date_ok = _date_matches(extracted, truth)

    return ReceiptScore(
        name=result_path.stem.replace(".jpg", ""),
        level=truth.get("level", "real"),
        expected_items=len(expected),
        matched_items=matched,
        extracted_items=len(extracted.items),
        discounts_expected=sum(1 for _, discount in expected if discount > 0),
        discounts_matched=discounts_matched,
        total_ok=total_ok,
        checksum_ok=extracted.checksum_ok,
        date_ok=date_ok,
    )


def _date_matches(extracted: ExtractedReceipt, truth: dict) -> bool:
    if extracted.date is None:
        return False
    day, month, year = truth["date"].split("/")
    return extracted.date == f"{year}-{month}-{day}"


def main() -> None:
    import sys

    target = sys.argv[1] if len(sys.argv) > 1 else "emulator_all"
    results_dir = ROOT / "results" / target
    truth_dir = ROOT / "corpus_synthetic" / "truth"

    scores: list[ReceiptScore] = []
    for truth_path in sorted(truth_dir.glob("*.json")):
        result_path = results_dir / f"{truth_path.stem}.jpg.json"
        if not result_path.exists():
            print(f"missing OCR result for {truth_path.stem}")
            continue
        scores.append(score_receipt(result_path, truth_path))

    for level in ["clean", "photo", "hard"]:
        level_scores = [score for score in scores if score.level == level]
        _report(level, level_scores)


def _report(level: str, scores: list[ReceiptScore]) -> None:
    expected = sum(score.expected_items for score in scores)
    matched = sum(score.matched_items for score in scores)
    extracted = sum(score.extracted_items for score in scores)
    discounts_expected = sum(score.discounts_expected for score in scores)
    discounts_matched = sum(score.discounts_matched for score in scores)
    recall = matched / expected if expected else 0.0
    precision = matched / extracted if extracted else 0.0
    checksum = sum(score.checksum_ok for score in scores)
    total_ok = sum(score.total_ok for score in scores)
    date_ok = sum(score.date_ok for score in scores)

    print(f"\n=== {level} ({len(scores)} tickets)")
    print(f"  articles  : recall {recall:.1%} ({matched}/{expected}), precision {precision:.1%} ({matched}/{extracted})")
    if discounts_expected:
        print(f"  remises   : {discounts_matched}/{discounts_expected}")
    print(f"  total lu  : {total_ok}/{len(scores)}, checksum ok {checksum}/{len(scores)}, date ok {date_ok}/{len(scores)}")
    for score in scores:
        flag = "OK " if score.matched_items == score.expected_items and score.checksum_ok else "ko "
        print(
            f"  {flag}{score.name}: {score.matched_items}/{score.expected_items} matched, "
            f"{score.extracted_items} extracted, checksum={'Y' if score.checksum_ok else 'N'}"
        )


if __name__ == "__main__":
    main()
