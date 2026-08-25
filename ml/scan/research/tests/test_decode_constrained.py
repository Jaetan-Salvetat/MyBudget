import math
from typing import ClassVar

from reference.decode_constrained import (
    DISCOUNT,
    IGNORE,
    ITEM,
    PAYMENT,
    TOTAL,
    LineOptions,
    best_assignment,
)


def options(
    cents: int, p_item: float, p_discount: float, p_ignore: float
) -> LineOptions:
    return LineOptions(
        cents=cents,
        log_probs={
            ITEM: math.log(p_item),
            DISCOUNT: math.log(p_discount),
            IGNORE: math.log(p_ignore),
        },
    )


class TestBestAssignment:
    def test_argmax_when_it_already_sums_to_target(self):
        lines = [options(200, 0.9, 0.05, 0.05), options(300, 0.9, 0.05, 0.05)]
        assert best_assignment(lines, 500) == [ITEM, ITEM]

    def test_drops_least_confident_line_to_hit_target(self):
        lines = [
            options(200, 0.9, 0.05, 0.05),
            options(300, 0.9, 0.05, 0.05),
            options(435, 0.5, 0.05, 0.45),
        ]
        assert best_assignment(lines, 500) == [ITEM, ITEM, IGNORE]

    def test_promotes_ignored_line_when_needed(self):
        lines = [
            options(200, 0.9, 0.05, 0.05),
            options(300, 0.4, 0.05, 0.55),
        ]
        assert best_assignment(lines, 500) == [ITEM, ITEM]

    def test_discount_subtracts(self):
        lines = [
            options(1000, 0.9, 0.05, 0.05),
            options(-250, 0.05, 0.9, 0.05),
        ]
        assert best_assignment(lines, 750) == [ITEM, DISCOUNT]

    def test_positive_discount_line_subtracts_too(self):
        lines = [
            options(1000, 0.9, 0.05, 0.05),
            options(250, 0.3, 0.6, 0.1),
        ]
        assert best_assignment(lines, 750) == [ITEM, DISCOUNT]

    def test_no_solution_returns_none(self):
        lines = [options(200, 0.9, 0.05, 0.05), options(300, 0.9, 0.05, 0.05)]
        assert best_assignment(lines, 999) is None

    def test_prefers_most_probable_among_solutions(self):
        lines = [
            options(500, 0.6, 0.05, 0.35),
            options(200, 0.9, 0.05, 0.05),
            options(300, 0.9, 0.05, 0.05),
        ]
        assert best_assignment(lines, 500) == [IGNORE, ITEM, ITEM]

    def test_label_below_floor_is_forbidden(self):
        lines = [
            options(200, 0.9, 0.05, 0.05),
            options(300, 0.001, 0.001, 0.998),
        ]
        assert best_assignment(lines, 500, min_prob=0.01) is None

    def test_empty_lines(self):
        assert best_assignment([], 0) == []


class TestLineOptions:
    def _options(
        self, prices, cutoff_rank, forced_ignore=frozenset(), reference_rank=None
    ):
        import numpy as np

        from reference.decode_constrained import _line_options

        class Priced:
            def __init__(self, price):
                self.price = price

        probas = np.array([[0.8, 0.1, 0.05, 0.0, 0.05]] * len(prices))
        return _line_options(
            [Priced(p) for p in prices],
            probas,
            cutoff_rank,
            forced_ignore,
            reference_rank,
        )

    def test_zero_cent_line_is_never_an_item(self):
        opts = self._options([0.0, 2.0], cutoff_rank=5)
        assert list(opts[0].log_probs) == [IGNORE]
        assert ITEM in opts[1].log_probs

    def test_lines_after_cutoff_are_forced_to_ignore(self):
        opts = self._options([2.0, 3.0, 5.0, 1.5], cutoff_rank=2, reference_rank=2)
        assert ITEM in opts[0].log_probs and ITEM in opts[1].log_probs
        assert list(opts[2].log_probs) == [IGNORE]
        assert list(opts[3].log_probs) == [IGNORE]

    def test_negative_price_cannot_be_an_item(self):
        opts = self._options([2.0, -1.0, 5.0], cutoff_rank=2)
        assert ITEM not in opts[1].log_probs
        assert DISCOUNT in opts[1].log_probs

    def test_forced_ignore_rank_has_no_other_option(self):
        opts = self._options(
            [2.0, 3.0, 5.0], cutoff_rank=2, forced_ignore=frozenset({1})
        )
        assert list(opts[1].log_probs) == [IGNORE]


def _priced(rows):
    from test_structure import receipt_lines

    from reference.line_features import priced_lines

    return priced_lines(receipt_lines(rows))


def _decode(rows, probas, alternatives=None, **params):
    import numpy as np

    from reference.decode_constrained import decode

    lines = _priced(rows)
    assert len(lines) == len(probas)
    return decode(lines, np.array(probas), alternatives=alternatives, **params)


ITEM_P = [0.99, 0.0, 0.0, 0.0, 0.01]
IGNORE_P = [0.01, 0.0, 0.0, 0.0, 0.99]
TOTAL_P = [0.0, 0.0, 0.99, 0.0, 0.01]
PAYMENT_P = [0.0, 0.0, 0.0, 0.99, 0.01]


class TestPaymentFallback:
    ROWS: ClassVar = [
        [("PAIN", 0), ("2,00", 38)],
        [("LAIT", 0), ("3,00", 38)],
        [("TOTAL", 0), ("9,90", 38)],
        [("CB", 0), ("5,00", 38)],
    ]

    def test_payment_verifies_when_argmax_items_land_on_it(self):
        hypothesis = _decode(self.ROWS, [ITEM_P, ITEM_P, TOTAL_P, PAYMENT_P])
        assert hypothesis is not None
        assert hypothesis.reference_role == PAYMENT
        assert hypothesis.labels[:2] == [ITEM, ITEM]

    def test_payment_never_flips_a_line(self):
        probas = [ITEM_P, [0.55, 0.0, 0.0, 0.0, 0.45], TOTAL_P, PAYMENT_P]
        rows = [self.ROWS[0], self.ROWS[1], self.ROWS[2], [("CB", 0), ("2,00", 38)]]
        assert _decode(rows, probas) is None


class TestReferences:
    def test_virtual_tax_reference_verifies_items_without_total_line(self):
        rows = [
            [("CAFE", 0), ("4.50", 38)],
            [("CHOCOLAT", 0), ("5.80", 38)],
            [("TVA", 0), ("10%", 4), ("0.94", 38)],
            [("HT", 0), ("9.36", 38)],
            [("10.30", 38)],
        ]
        probas = [
            ITEM_P,
            ITEM_P,
            IGNORE_P,
            [0.9, 0.0, 0.0, 0.0, 0.1],
            [0.0, 0.0, 0.02, 0.0, 0.98],
        ]
        hypothesis = _decode(rows, probas)
        assert hypothesis.reference_cents == 1030
        assert hypothesis.labels == [ITEM, ITEM, IGNORE, IGNORE, IGNORE]

    def test_subtotal_before_a_discount_is_never_the_reference(self):
        rows = [
            [("CAFE", 0), ("4,35", 38)],
            [("14.12", 38)],
            [("S/TOT", 0), ("18.47", 38)],
            [("SUB", 0), ("ORANGE", 4), ("-14.12", 37)],
            [("TOTAL", 0), ("4,35", 38)],
        ]
        probas = [
            ITEM_P,
            [0.85, 0.0, 0.0, 0.0, 0.15],
            [0.0, 0.0, 0.96, 0.0, 0.04],
            [0.0, 0.97, 0.0, 0.0, 0.03],
            TOTAL_P,
        ]
        hypothesis = _decode(rows, probas)
        assert hypothesis.reference_cents == 435
        assert hypothesis.labels[2] == IGNORE and hypothesis.labels[4] == TOTAL

    def test_section_total_is_never_the_reference(self):
        rows = [
            [("PAIN", 0), ("0,99", 38)],
            [("TOTAL", 0), ("ALIMENTAIRE", 6), ("0,99", 38)],
            [("SAVON", 0), ("2,00", 38)],
            [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("2,99", 38)],
        ]
        probas = [ITEM_P, [0.0, 0.0, 0.6, 0.0, 0.4], ITEM_P, TOTAL_P]
        hypothesis = _decode(rows, probas)
        assert hypothesis.reference_cents == 299
        assert hypothesis.labels == [ITEM, IGNORE, ITEM, TOTAL]

    def test_summary_discount_is_ignored(self):
        rows = [
            [("LIT", 0), ("55,00", 38)],
            [("Nouveau", 0), ("prix", 8), ("49,90", 14), ("-5,10", 37)],
            [("REMISE", 0), ("TOTALE", 7), ("-5,10", 37)],
            [("TOTAL", 0), ("49,90", 38)],
        ]
        probas = [
            ITEM_P,
            [0.05, 0.9, 0.0, 0.0, 0.05],
            [0.0, 0.99, 0.0, 0.0, 0.01],
            TOTAL_P,
        ]
        hypothesis = _decode(rows, probas)
        assert hypothesis.labels == [ITEM, DISCOUNT, IGNORE, TOTAL]

    def test_payment_minus_change_verifies_items(self):
        rows = [
            [("Soupe", 0), ("7,98", 38)],
            [("Soupe", 0), ("7,98", 38)],
            [("Espèces", 0), ("20,00", 38)],
            [("Rendu", 0), ("Espèces", 6), ("4,04", 38)],
        ]
        probas = [ITEM_P, ITEM_P, [0.0, 0.0, 0.0, 0.9, 0.1], IGNORE_P]
        hypothesis = _decode(rows, probas)
        assert hypothesis.reference_cents == 1596
        assert hypothesis.labels == [ITEM, ITEM, IGNORE, IGNORE]

    def test_concordant_sources_outrank_a_lone_classifier_total(self):
        rows = [
            [("VIN", 0), ("17,00", 38)],
            [("3,00", 38)],
            [("TOTAL", 0), ("TTC", 6), ("20,00", 38)],
            [("TOTAL", 0), ("17,00", 38)],
            [("TVA", 0), ("10%", 4), ("1,55", 38)],
            [("HT", 0), ("15,45", 38)],
        ]
        probas = [
            ITEM_P,
            [0.5, 0.0, 0.0, 0.0, 0.5],
            [0.0, 0.0, 0.9, 0.0, 0.1],
            [0.0, 0.0, 0.6, 0.0, 0.4],
            IGNORE_P,
            IGNORE_P,
        ]
        hypothesis = _decode(rows, probas)
        assert hypothesis.reference_cents == 1700
        assert hypothesis.labels[1] == IGNORE


class TestSingleItem:
    PARKING: ClassVar = [
        [("PRIX", 0), ("HT", 5), ("12,25", 36)],
        [("TVA", 0), ("20,00%", 4), ("2,45", 36)],
        [("PRIX", 0), ("TTC", 5), ("14,70", 36)],
    ]
    PROBAS: ClassVar = [
        [0.9, 0.0, 0.0, 0.0, 0.1],
        IGNORE_P,
        [0.92, 0.0, 0.08, 0.0, 0.0],
    ]

    def test_tax_proof_with_nothing_else_priced_is_a_single_item(self):
        hypothesis = _decode(self.PARKING, self.PROBAS)
        assert hypothesis.single_item
        assert hypothesis.reference_cents == 1470
        assert hypothesis.labels == [IGNORE, IGNORE, TOTAL]

    def test_refused_when_printed_count_expects_several_items(self):
        assert _decode(self.PARKING, self.PROBAS, printed_count=2) is None

    def test_refused_without_an_arithmetic_source(self):
        rows = [
            [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("4.70", 38)],
            [("ESPECES", 0), ("4.70", 38)],
        ]
        assert _decode(rows, [TOTAL_P, PAYMENT_P]) is None

    def test_refused_when_an_item_candidate_exists(self):
        rows = [
            [("CAFE", 0), ("1,00", 38)],
            [("PRIX", 0), ("HT", 5), ("12,25", 36)],
            [("TVA", 0), ("20,00%", 4), ("2,45", 36)],
            [("PRIX", 0), ("TTC", 5), ("14,70", 36)],
        ]
        assert _decode(rows, [ITEM_P, *self.PROBAS]) is None


class TestAmountAlternatives:
    def test_alternative_amount_is_used_when_the_primary_cannot_sum(self):
        from reference.decode_constrained import best_assignment_detail

        lines = [
            options(200, 0.9, 0.05, 0.05),
            LineOptions(
                cents=5275,
                log_probs={ITEM: math.log(0.9), IGNORE: math.log(0.1)},
                alternative_cents=275,
            ),
        ]
        assignment = best_assignment_detail(lines, 475)
        assert assignment.labels == [ITEM, ITEM]
        assert assignment.cents == [200, 275]

    def test_primary_amount_is_preferred_when_both_sum(self):
        from reference.decode_constrained import best_assignment_detail

        lines = [
            LineOptions(
                cents=200,
                log_probs={ITEM: math.log(0.9), IGNORE: math.log(0.1)},
                alternative_cents=200,
            ),
        ]
        assert best_assignment_detail(lines, 200).cents == [200]

    def test_decode_with_alternatives_rewrites_the_chosen_amount(self):
        rows = [
            [("TORT", 0), ("RICOTTA", 5), ("S2.75e", 36)],
            [("PAIN", 0), ("2,00", 38)],
            [("TOTAL", 0), ("4,75", 38)],
        ]
        probas = [ITEM_P, ITEM_P, TOTAL_P]
        hypothesis = _decode(rows, probas, alternatives={0: 275})
        assert hypothesis.labels == [ITEM, ITEM, TOTAL]
        assert hypothesis.cents[0] == 275

    def test_forced_ignore_lines_keep_their_price(self):
        from reference.decode_constrained import _with_chosen_amounts

        lines = _priced([[("PAIN", 0), ("2,00", 38)], [("TOTAL", 0), ("2,00", 38)]])
        rewritten = _with_chosen_amounts(lines, [ITEM, TOTAL], [200, 0])
        assert [p.price for p in rewritten] == [2.0, 2.0]


class TestSectionTotals:
    def test_bare_section_total_can_be_ignored_despite_the_classifier(self):
        rows = [
            [("POUDRE", 0), ("1.64", 38)],
            [("YAOURT", 0), ("1.30", 38)],
            [("ALINENTAIRE", 0), ("2.94", 38)],
            [("SAVON", 0), ("2.07", 38)],
            [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("5.01", 38)],
        ]
        probas = [ITEM_P, ITEM_P, [0.995, 0.0, 0.0, 0.0, 0.005], ITEM_P, TOTAL_P]
        hypothesis = _decode(rows, probas)
        assert hypothesis.labels == [ITEM, ITEM, IGNORE, ITEM, TOTAL]

    def test_sections_sum_verifies_when_the_final_total_is_unreadable(self):
        rows = [
            [("PURE", 0), ("7,05", 38)],
            [("KIT", 0), ("5,50", 38)],
            [("Total", 0), ("Soins", 6), ("12,55", 38)],
            [("CRF", 0), ("KIT", 4), ("9.90", 38)],
            [("Total", 0), ("Non", 6), ("Alimentaire", 10), ("9.90", 38)],
        ]
        probas = [ITEM_P, ITEM_P, IGNORE_P, ITEM_P, [0.0, 0.0, 0.78, 0.0, 0.22]]
        hypothesis = _decode(rows, probas)
        assert hypothesis.reference_cents == 2245
        assert hypothesis.labels == [ITEM, ITEM, IGNORE, ITEM, IGNORE]
