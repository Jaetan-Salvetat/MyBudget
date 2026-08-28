import random

from evaluation.robustness import EVAL_ONLY_OPERATORS, NORMALIZATION_OPERATORS
from serving.normalize import normalize_query, normalize_receipt_line
from training.corruption import TRAIN_OPERATORS, corrupt


def test_query_normalization_unglues_punctuation():
    assert normalize_query("father &son") == "father & son"
    assert normalize_query("Father& Son") == "father & son"
    assert normalize_query("FATHER&SON") == "father & son"
    assert normalize_query("father  &  son") == "father & son"


def test_query_normalization_folds_accents_and_case():
    assert normalize_query("Marché péage crèche") == "marche peage creche"
    assert normalize_query("MARCHE PEAGE CRECHE") == "marche peage creche"


def test_query_normalization_unifies_apostrophes_and_dashes():
    assert normalize_query("aujourd’hui") == normalize_query("aujourd'hui")
    assert normalize_query("week—end") == "week-end"


def test_query_normalization_is_idempotent():
    for text in ("Café Père & Fils !!", "N°42 — Zalando", "aujourd’hui 12,50 €"):
        once = normalize_query(text)
        assert normalize_query(once) == once


def test_query_normalization_never_empties_a_text():
    assert normalize_query("???") == "?"
    assert normalize_query("   ") == ""


def test_receipt_normalization_folds_accents():
    assert normalize_receipt_line("*160G PÂTÉ CROÛTE") == "pate croute"


def test_corruption_stays_in_canonical_form():
    rng = random.Random(0)
    for _ in range(200):
        noisy = corrupt("carrefour market la rochelle", rng)
        assert normalize_query(noisy) == noisy


def test_corruption_alters_a_single_word_at_most():
    rng = random.Random(1)
    clean = "abonnement netflix mensuel"
    for _ in range(200):
        noisy = corrupt(clean, rng)
        differing = [
            index
            for index, (before, after) in enumerate(zip(clean.split(), noisy.split()))
            if before != after
        ]
        assert len(noisy.split()) == len(clean.split())
        assert len(differing) <= 1


def test_corruption_leaves_short_words_and_numbers_alone():
    rng = random.Random(2)
    clean = "carrefour 12,50 le 8"
    for _ in range(200):
        head, *tail = corrupt(clean, rng).split(" ")
        assert tail == ["12,50", "le", "8"]
        assert head.isalpha()


def test_corruption_is_deterministic_for_a_seed():
    first = [corrupt("boulangerie martin", random.Random(seed)) for seed in range(20)]
    second = [corrupt("boulangerie martin", random.Random(seed)) for seed in range(20)]
    assert first == second


def test_corruption_actually_corrupts_often_enough():
    rng = random.Random(3)
    texts = [corrupt("carrefour contact", rng) for _ in range(1000)]
    altered = sum(text != "carrefour contact" for text in texts)
    assert 200 <= altered <= 500


def test_evaluation_operators_are_held_out_from_training():
    assert not set(EVAL_ONLY_OPERATORS) & set(TRAIN_OPERATORS)
    assert not set(NORMALIZATION_OPERATORS) & set(TRAIN_OPERATORS)


def test_evaluation_operators_change_the_text():
    rng = random.Random(4)
    for name, operator in {**EVAL_ONLY_OPERATORS, **NORMALIZATION_OPERATORS}.items():
        assert operator("marché carrefour city", rng) != "marché carrefour city", name
