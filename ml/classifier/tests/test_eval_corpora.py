import json
from pathlib import Path

import pytest

from evaluation.generalization import FAMILIES, family
from evaluation.world import CASE_FIELDS, is_known
from evaluation.robustness import TYPOS_PATH
from paths import QUICK_ADD_CORPUS, WORLD_CORPUS
from serving.normalize import normalize_query
from taxonomy import ACTIVE_LABELS, LABELS, canonical, type_of

WORLD_PATH = WORLD_CORPUS
LEGACY_PATH = QUICK_ADD_CORPUS

TYPES = {"expense", "income"}
RECURRENCES = {"ponctuel", "fixe"}
AXES = {"brand_physical", "service_online", "product", "common_noun", "local_business"}
# Deux familles de fautes : celles que la normalisation efface avant le modèle,
# et celles qu'il doit comprendre lui-même.
NORMALIZED_AWAY_AXES = {"ponctuation", "casse"}
MODEL_AXES = {"frappe", "phonetique", "agglutination", "coupure"}
TYPO_AXES = NORMALIZED_AWAY_AXES | MODEL_AXES


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


def test_world_corpus_is_tagged_by_axis():
    for case in _cases(WORLD_PATH):
        assert case["axis"] in AXES, case["input"]


def test_world_corpus_covers_every_active_class():
    covered = {canonical(case["category"]) for case in _cases(WORLD_PATH)}
    assert set(ACTIVE_LABELS) - covered == set()


def test_world_corpus_covers_every_axis():
    seen = {case["axis"] for case in _cases(WORLD_PATH)}
    assert AXES - seen == set()


# L'app ne sert que des francophones : une entree anglaise dans la grille
# d'acceptation mesure une langue que le corpus n'apprend plus.
ENGLISH_PHRASING = (
    "paid", "bought", "spent", "received", "yesterday", "last week", "monthly",
    "subscription", "groceries", "dinner out", "with friends", "for the",
)


@pytest.mark.parametrize("path", [WORLD_PATH, LEGACY_PATH])
def test_acceptance_corpora_carry_no_english_phrasing(path: Path):
    for case in _cases(path):
        lowered = case["input"].lower()
        assert not any(marker in lowered for marker in ENGLISH_PHRASING), case["input"]


def test_families_only_group_slugs_of_the_taxonomy():
    for slug in FAMILIES:
        assert slug in LABELS, slug
    assert family("transport.carburant") == "transport.carburant"


def test_every_case_carries_exactly_what_the_evaluation_reads():
    for case in _cases(WORLD_PATH):
        assert set(case) == set(CASE_FIELDS), case["input"]


def test_known_detection_matches_on_word_boundaries():
    names = {"carrefour", "uber eats"}
    assert is_known("courses Carrefour 85", names)
    assert is_known("Uber Eats 24", names)
    assert not is_known("carrefourgeoisie", names)


def test_typo_corpus_is_a_fault_over_a_known_name():
    """Sans la forme correcte à côté, la chute mesurée ne veut rien dire."""
    cases = _cases(TYPOS_PATH)
    assert len(cases) >= 60
    for case in cases:
        assert case["axis"] in TYPO_AXES, case["input"]
        assert canonical(case["category"]) in ACTIVE_LABELS, case["input"]
        assert case["input"] != case["clean"], case["input"]


def test_typo_corpus_covers_every_axis():
    covered = {case["axis"] for case in _cases(TYPOS_PATH)}
    assert covered == TYPO_AXES


def test_the_rule_absorbs_what_it_claims_and_leaves_the_rest_to_the_modele():
    """Casse et ponctuation disparaissent avant le modèle ; le reste lui arrive."""
    for case in _cases(TYPOS_PATH):
        same = normalize_query(case["input"]) == normalize_query(case["clean"])
        if case["axis"] in NORMALIZED_AWAY_AXES:
            assert same, case["input"]
        else:
            assert not same, case["input"]
