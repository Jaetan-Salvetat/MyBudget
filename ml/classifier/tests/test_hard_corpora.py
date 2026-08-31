"""Ce qui fait qu'un corpus dur mesure encore quelque chose dans six mois.

Les deux corpus d'acceptation précédents ont dérivé de la même façon : écrits à
la main dans le vocabulaire du générateur, ils ont fini par mesurer la
distribution d'entraînement et à annoncer 98 % là où l'app en rendait bien
moins. Le corpus scan a dérivé autrement — 75 % de ses articles portent la même
classe, et répondre « supermarché » à tout y suffisait.

Chaque invariant ci-dessous est l'un de ces deux naufrages, rendu impossible.
"""

import json
from pathlib import Path

import pytest

from corpus.quick_add.build import (
    FR_CONTEXTS,
    FR_EXPENSE_PREFIXES,
    FR_INCOME_PREFIXES,
    FR_SUFFIXES,
)
from paths import DATASET_DIR, EVAL_DATA_DIR
from serving.normalize import normalize_query, normalize_receipt_line
from taxonomy import ACTIVE_LABELS, canonical, type_of

HARD_QUICK_ADD = EVAL_DATA_DIR / "hard_quick_add.json"
HARD_RECEIPTS = EVAL_DATA_DIR / "hard_receipts.json"

QUICK_ADD_AXES = {
    "marque_nue", "homographe", "contexte", "sans_entite", "argot",
    "phrase_libre", "recurrence", "revenu", "chiffre", "commerce_local",
}
RECEIPTS_AXES = {"hors_alimentaire", "restauration", "confusable", "abrege"}

TYPES = {"expense", "income"}
RECURRENCES = {"ponctuel", "fixe"}

# Une classe qui pèse le quart du corpus rend la moyenne illisible : c'est ce
# qui faisait annoncer 68 % au scan quand « supermarché » partout en valait 75.
QUICK_ADD_CLASS_CAP = 0.06
RECEIPTS_CLASS_CAP = 0.25

# Le générateur ne connaît qu'une vingtaine de préfixes et une quarantaine de
# suffixes. Un corpus qui les reprend mesure le gabarit, pas l'utilisateur.
TEMPLATE_CAP = 0.25

ENGLISH_PHRASING = (
    "paid", "bought", "spent", "received", "yesterday", "last week", "monthly",
    "subscription", "groceries", "dinner out", "with friends", "for the",
)


def cases(path: Path) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))["cases"]


def texts_of(path: Path) -> set[str]:
    return {json.loads(line)["text"] for line in path.read_text(encoding="utf-8").splitlines()}


@pytest.mark.parametrize("path", [HARD_QUICK_ADD, HARD_RECEIPTS])
def test_labels_stay_inside_the_active_taxonomy(path: Path):
    for case in cases(path):
        assert canonical(case["category"]) in ACTIVE_LABELS, case
        assert case["type"] in TYPES, case


@pytest.mark.parametrize("path", [HARD_QUICK_ADD, HARD_RECEIPTS])
def test_type_matches_the_category_section(path: Path):
    for case in cases(path):
        expected = "expense" if type_of(canonical(case["category"])) == 0 else "income"
        assert case["type"] == expected, case


def test_quick_add_cases_carry_a_known_axis_and_recurrence():
    for case in cases(HARD_QUICK_ADD):
        assert case["axis"] in QUICK_ADD_AXES, case
        assert case["recurrence"] in RECURRENCES, case


def test_receipt_cases_carry_a_known_axis():
    for case in cases(HARD_RECEIPTS):
        assert case["axis"] in RECEIPTS_AXES, case


@pytest.mark.parametrize(
    ("path", "axes"), [(HARD_QUICK_ADD, QUICK_ADD_AXES), (HARD_RECEIPTS, RECEIPTS_AXES)]
)
def test_every_axis_is_populated(path: Path, axes: set[str]):
    assert {case["axis"] for case in cases(path)} == axes


def test_quick_add_corpus_covers_every_active_class():
    """Une classe sans cas dur est une classe dont on ne saura rien."""
    covered = {canonical(case["category"]) for case in cases(HARD_QUICK_ADD)}
    assert set(ACTIVE_LABELS) - covered == set()


@pytest.mark.parametrize(
    ("path", "cap"), [(HARD_QUICK_ADD, QUICK_ADD_CLASS_CAP), (HARD_RECEIPTS, RECEIPTS_CLASS_CAP)]
)
def test_no_class_dominates_the_corpus(path: Path, cap: float):
    rows = cases(path)
    counts: dict[str, int] = {}
    for case in rows:
        counts[case["category"]] = counts.get(case["category"], 0) + 1
    heaviest, weight = max(counts.items(), key=lambda item: item[1])
    assert weight / len(rows) <= cap, f"{heaviest} pèse {weight / len(rows):.1%}"


def test_no_duplicate_case():
    for path, normalize, field in (
        (HARD_QUICK_ADD, normalize_query, "input"),
        (HARD_RECEIPTS, normalize_receipt_line, "name"),
    ):
        forms = [normalize(case[field]) for case in cases(path)]
        assert len(forms) == len(set(forms))


def test_no_case_carries_english_phrasing():
    for case in cases(HARD_QUICK_ADD):
        lowered = case["input"].lower()
        assert not any(marker in lowered for marker in ENGLISH_PHRASING), case


def test_receipt_labels_survive_the_receipt_normalization():
    """Un libellé que la normalisation vide mesurerait la règle, pas le modèle."""
    for case in cases(HARD_RECEIPTS):
        assert normalize_receipt_line(case["name"]).strip(), case


def test_quick_add_phrasing_escapes_the_generator_templates():
    rows = cases(HARD_QUICK_ADD)
    templates = set(FR_EXPENSE_PREFIXES + FR_INCOME_PREFIXES + FR_SUFFIXES + FR_CONTEXTS)
    reused = [
        case
        for case in rows
        if any(f" {piece} " in f" {case['input'].lower()} " for piece in templates)
    ]
    assert len(reused) / len(rows) <= TEMPLATE_CAP


@pytest.mark.skipif(
    not (DATASET_DIR / "train.jsonl").exists(),
    reason="corpus d'entraînement absent : `./tool/ml_data/fetch.sh classifier`",
)
def test_no_hard_case_outside_the_control_axis_is_verbatim_in_training():
    """`marque_nue` mesure la mémorisation et l'assume ; les autres axes non."""
    trained = texts_of(DATASET_DIR / "train.jsonl")
    leaked = [
        case["input"]
        for case in cases(HARD_QUICK_ADD)
        if case["axis"] != "marque_nue" and normalize_query(case["input"]) in trained
    ]
    assert len(leaked) / len(cases(HARD_QUICK_ADD)) <= 0.10, leaked


@pytest.mark.skipif(
    not (DATASET_DIR / "receipts_train.jsonl").exists(),
    reason="corpus ticket absent : `./tool/ml_data/fetch.sh classifier`",
)
def test_no_receipt_label_is_learnt_verbatim():
    trained = texts_of(DATASET_DIR / "receipts_train.jsonl")
    leaked = [
        case["name"]
        for case in cases(HARD_RECEIPTS)
        if normalize_receipt_line(case["name"]) in trained
    ]
    assert leaked == []


def test_verb_phrases_never_copy_the_hard_corpus():
    """Le lexique verbal vise la capacité que l'axe mesure, jamais ses phrases.

    Il a été écrit après avoir constaté l'échec de `phrase_libre` : sans cette
    barrière, corriger le modèle reviendrait à recopier la grille dans le
    corpus, et l'axe cesserait de mesurer quoi que ce soit.
    """
    from corpus.quick_add.verbs import VERB_PHRASES

    written = {normalize_query(clause) for clauses in VERB_PHRASES.values() for clause in clauses}
    measured = {normalize_query(case["input"]) for case in cases(HARD_QUICK_ADD)}
    assert written & measured == set()


def test_verb_phrases_stay_inside_the_active_taxonomy():
    from corpus.quick_add.verbs import VERB_PHRASES

    for slug in VERB_PHRASES:
        assert canonical(slug) in ACTIVE_LABELS, slug
