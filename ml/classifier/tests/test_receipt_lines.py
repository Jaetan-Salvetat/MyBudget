import json
import random

import pytest

from corpus.receipts.lines import (
    KEY_PREFIX,
    LINE_VARIANTS,
    LINES_DIR,
    generated_lines,
    read_lines,
)
from paths import EVAL_DATA_DIR, RECEIPTS_CORPUS
from serving.normalize import normalize_receipt_line
from taxonomy import ACTIVE_LABELS, LABEL_INDEX, NUM_EXPENSE

MIN_PER_CLASS = 120

pytestmark = pytest.mark.skipif(not any(LINES_DIR.glob("*.json")), reason="lignes absentes")


def measured_lines() -> set[str]:
    out: set[str] = set()
    hard = EVAL_DATA_DIR / "hard_receipts.json"
    if hard.exists():
        out.update(
            normalize_receipt_line(case["name"])
            for case in json.loads(hard.read_text(encoding="utf-8"))["cases"]
        )
    if RECEIPTS_CORPUS.exists():
        out.update(
            normalize_receipt_line(row["name"])
            for row in json.loads(RECEIPTS_CORPUS.read_text(encoding="utf-8"))
            if row["split"] == "test"
        )
    return out


def test_every_covered_class_is_an_expense_with_enough_lines():
    for slug, entries in read_lines().items():
        assert slug in ACTIVE_LABELS and LABEL_INDEX[slug] < NUM_EXPENSE, slug
        assert len(entries) >= MIN_PER_CLASS, slug


def test_lines_never_copy_a_measured_label():
    measured = measured_lines()
    copied = [
        entry
        for entries in read_lines().values()
        for entry in entries
        if normalize_receipt_line(entry) in measured
    ]
    assert copied == []


def test_lines_are_distinct_once_normalized_within_a_class():
    for slug, entries in read_lines().items():
        forms = [normalize_receipt_line(entry) for entry in entries]
        assert len(forms) == len(set(forms)), slug


def test_generated_lines_are_keyed_per_line_and_normalized():
    rows = generated_lines(random.Random(1))
    assert rows
    for key, text, slug in rows:
        assert key.startswith(KEY_PREFIX) and slug in key
        assert text == normalize_receipt_line(text)
    per_key: dict[str, int] = {}
    for key, _text, _slug in rows:
        per_key[key] = per_key.get(key, 0) + 1
    assert set(per_key.values()) == {LINE_VARIANTS}
