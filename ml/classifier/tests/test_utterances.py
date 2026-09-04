import json
import re

import pytest

from corpus.quick_add.utterances import (
    RECURRENCE_VALUES,
    SOURCE,
    UTTERANCES_DIR,
    read_utterances,
    utterance_entities,
)
from paths import EVAL_DATA_DIR
from serving.normalize import normalize_query
from taxonomy import ACTIVE_LABELS, RECURRING, canonical

AMOUNT = re.compile(r"\d+\s?(?:€|euros?)\b", re.IGNORECASE)
MIN_PER_CLASS = 100
EVALUATION_CORPORA = ("hard_quick_add.json", "world.json", "quick_add.json", "fresh_quick_add.json")

pytestmark = pytest.mark.skipif(
    not any(UTTERANCES_DIR.glob("*.json")), reason="formulations absentes"
)


def evaluation_inputs() -> set[str]:
    out: set[str] = set()
    for name in EVALUATION_CORPORA:
        path = EVAL_DATA_DIR / name
        if path.exists():
            cases = json.loads(path.read_text(encoding="utf-8"))["cases"]
            out.update(normalize_query(case["input"]) for case in cases)
    return out


def test_every_active_class_has_enough_utterances():
    counts: dict[str, int] = {}
    for utterance in read_utterances():
        counts[utterance.slug] = counts.get(utterance.slug, 0) + 1
    thin = {slug: counts.get(slug, 0) for slug in ACTIVE_LABELS if counts.get(slug, 0) < MIN_PER_CLASS}
    assert thin == {}


def test_utterances_stay_inside_the_active_taxonomy():
    for utterance in read_utterances():
        assert canonical(utterance.slug) in ACTIVE_LABELS, utterance
        assert utterance.recurrence in RECURRENCE_VALUES.values(), utterance


def test_utterances_never_copy_an_evaluation_corpus():
    measured = evaluation_inputs()
    copied = [u.text for u in read_utterances() if normalize_query(u.text) in measured]
    assert copied == []


def test_utterances_carry_no_amount():
    priced = [u.text for u in read_utterances() if AMOUNT.search(u.text)]
    assert priced == []


def test_utterances_are_distinct_once_normalized():
    forms = [normalize_query(u.text) for u in read_utterances()]
    assert len(forms) == len(set(forms))


def test_utterance_entities_carry_their_recurrence_and_source():
    entities = utterance_entities()
    assert entities
    assert {entity.source for entity in entities} == {SOURCE}
    assert any(entity.recurrence == RECURRING for entity in entities)
    by_text = {entity.name: entity for entity in entities}
    for utterance in read_utterances():
        assert by_text[utterance.text].recurrence == utterance.recurrence
