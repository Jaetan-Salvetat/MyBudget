import math

from decode_constrained import (
    DISCOUNT,
    IGNORE,
    ITEM,
    PAYMENT,
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


class TestZeroCentLines:
    def test_zero_cent_line_is_never_an_item(self):
        import numpy as np

        from decode_constrained import _line_options

        class Priced:
            def __init__(self, price):
                self.price = price

        probas = np.array([[0.5, 0.0, 0.2, 0.0, 0.3], [0.9, 0.0, 0.0, 0.0, 0.1]])
        opts = _line_options([Priced(0.0), Priced(2.0)], probas, reference_rank=2)
        assert list(opts[0].log_probs) == [IGNORE]
        assert ITEM in opts[1].log_probs


class TestStructuralConstraints:
    def _options(self, prices, reference_rank):
        import numpy as np

        from decode_constrained import _line_options

        class Priced:
            def __init__(self, price):
                self.price = price

        probas = np.array([[0.8, 0.1, 0.05, 0.0, 0.05]] * len(prices))
        return _line_options([Priced(p) for p in prices], probas, reference_rank)

    def test_lines_after_reference_are_forced_to_ignore(self):
        opts = self._options([2.0, 3.0, 5.0, 1.5], reference_rank=2)
        assert ITEM in opts[0].log_probs and ITEM in opts[1].log_probs
        assert list(opts[2].log_probs) == [IGNORE]

    def test_negative_price_cannot_be_an_item(self):
        opts = self._options([2.0, -1.0, 5.0], reference_rank=2)
        assert ITEM not in opts[1].log_probs
        assert DISCOUNT in opts[1].log_probs


class TestPaymentFallback:
    def _lines_and_probas(self):
        import numpy as np

        class Priced:
            def __init__(self, price):
                self.price = price

        prices = [2.0, 3.0, 9.9, 5.0]
        probas = np.array(
            [
                [0.99, 0.0, 0.0, 0.0, 0.01],
                [0.99, 0.0, 0.0, 0.0, 0.01],
                [0.0, 0.0, 0.99, 0.0, 0.01],
                [0.0, 0.0, 0.0, 0.99, 0.01],
            ]
        )
        return [Priced(p) for p in prices], probas

    def test_payment_rescues_when_argmax_items_match_it(self):
        from decode_constrained import decode

        lines, probas = self._lines_and_probas()
        hypothesis = decode(lines, probas)
        assert hypothesis is not None
        assert hypothesis.reference_role == PAYMENT
        assert hypothesis.labels == [ITEM, ITEM, IGNORE, PAYMENT]

    def test_payment_never_rescues_with_a_flip(self):
        from decode_constrained import decode

        lines, probas = self._lines_and_probas()
        probas[1] = [0.6, 0.0, 0.0, 0.0, 0.4]
        lines[3].price = 2.0
        assert decode(lines, probas) is None
