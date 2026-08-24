import json
from pathlib import Path

import pytest

from eval_world import is_known
from taxonomy import ACTIVE_LABELS, LABELS, canonical, type_of

ROOT = Path(__file__).resolve().parents[1]
WORLD_PATH = ROOT / "eval_world.json"
LEGACY_PATH = ROOT / "eval_corpus.json"

TYPES = {"expense", "income"}
RECURRENCES = {"ponctuel", "fixe"}
AXES = {"brand_physical", "service_online", "product", "common_noun", "local_business"}
LANGUAGES = {"fr", "en"}


def _cases(path: Path) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))["cases"]


@pytest.mark.parametrize("path", [WORLD_PATH, LEGACY_PATH])
def test_corpus_labels_stay_inside_the_taxonomy(path: Path):
    for case in _cases(path):
        assert canonical(case["category"]) in LABELS, case["input"]
        assert case["type"] in TYPES, case["input"]
        assert case["recurrence"] in RECURRENCES, case["input"]


@pytest.mark.parametrize("path", [WORLD_PATH, LEGACY_PATH])
def test_corpus_type_matches_the_category_section(path: Path):
    for case in _cases(path):
        expected = "expense" if type_of(canonical(case["category"])) == 0 else "income"
        assert case["type"] == expected, case["input"]


def test_world_corpus_is_tagged_by_axis_and_language():
    for case in _cases(WORLD_PATH):
        assert case["axis"] in AXES, case["input"]
        assert case["lang"] in LANGUAGES, case["input"]


def test_world_corpus_covers_every_active_class():
    covered = {canonical(case["category"]) for case in _cases(WORLD_PATH)}
    assert set(ACTIVE_LABELS) - covered == set()


def test_world_corpus_covers_both_languages_on_every_axis():
    seen = {(case["axis"], case["lang"]) for case in _cases(WORLD_PATH)}
    for axis in AXES:
        assert (axis, "fr") in seen and (axis, "en") in seen, axis


def test_known_detection_matches_on_word_boundaries():
    names = {"carrefour", "uber eats"}
    assert is_known("courses Carrefour 85", names)
    assert is_known("Uber Eats 24", names)
    assert not is_known("carrefourgeoisie", names)
