from line_features_v3 import (
    EXTRA_FEATURE_NAMES,
    FEATURE_NAMES_V3,
    block_sum_matches,
    fuzzy_lexicon_similarity,
    hashed_trigrams,
    tax_shaped,
)


class TestBlockSum:
    def test_total_equals_contiguous_block_above(self):
        assert block_sum_matches([200, 300, -100, 400], 3) is True

    def test_single_line_above_does_not_count(self):
        assert block_sum_matches([400, 400], 1) is False

    def test_no_block(self):
        assert block_sum_matches([200, 300, 999], 2) is False

    def test_first_line_has_nothing_above(self):
        assert block_sum_matches([500], 0) is False


class TestTaxShaped:
    def test_ten_percent_of_other(self):
        assert tax_shaped(66, [66, 664, 730]) is True

    def test_twenty_percent_ttc_decomposition(self):
        assert tax_shaped(700, [4200, 3500, 700]) is True

    def test_ht_of_ttc(self):
        assert tax_shaped(3500, [4200, 3500]) is True

    def test_unrelated(self):
        assert tax_shaped(123, [999, 500]) is False


class TestFuzzyLexicon:
    def test_exact_word(self):
        assert fuzzy_lexicon_similarity("TOTAL TTC 7.30", ("TOTAL",)) == 1.0

    def test_ocr_substitution(self):
        assert fuzzy_lexicon_similarity("Tota1 HT 35,00", ("TOTAL",)) >= 0.8

    def test_split_word(self):
        assert fuzzy_lexicon_similarity("TOT AL 12.00", ("TOTAL",)) >= 0.8

    def test_unrelated_text(self):
        assert fuzzy_lexicon_similarity("BANANE 1.20", ("TOTAL",)) < 0.5

    def test_short_entries_need_exact_match(self):
        assert fuzzy_lexicon_similarity("MENTHE 2.00", ("HT",)) == 0.0
        assert fuzzy_lexicon_similarity("TOTAL HT 2.00", ("HT",)) == 1.0


class TestHashing:
    def test_deterministic_and_sized(self):
        a = hashed_trigrams("TOTAL", 64)
        b = hashed_trigrams("TOTAL", 64)
        assert a == b and len(a) == 64 and sum(a) > 0

    def test_digits_are_folded(self):
        assert hashed_trigrams("ART 123", 64) == hashed_trigrams("ART 456", 64)


def test_feature_names_are_consistent():
    assert FEATURE_NAMES_V3[-len(EXTRA_FEATURE_NAMES) :] == EXTRA_FEATURE_NAMES
    assert len(set(FEATURE_NAMES_V3)) == len(FEATURE_NAMES_V3)


class TestDiscountSummary:
    def test_negative_equal_to_sum_of_previous_negatives(self):
        from line_features_v3 import discount_summary

        assert discount_summary([500, -100, 300, -55, -155], 4) is True

    def test_single_previous_negative_does_not_count(self):
        from line_features_v3 import discount_summary

        assert discount_summary([500, -155, -155], 2) is False

    def test_positive_line_is_never_a_summary(self):
        from line_features_v3 import discount_summary

        assert discount_summary([-100, -55, 155], 2) is False
