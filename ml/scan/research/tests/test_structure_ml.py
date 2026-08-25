from test_structure import receipt_lines

from reference.line_features import PricedLine
from reference.structure_ml import DISCOUNT, IGNORE, ITEM, TOTAL, receipt_from_labels


def _priced(merged, index):
    line = merged[index]
    return PricedLine(
        index, line, float(line.words[-1].text.replace(",", ".")), line.words[-1]
    )


def _setup():
    merged = receipt_lines(
        [
            [("STORE", 10)],
            [("POMME", 0), ("2.00", 38)],
            [("REMISE", 0), ("-0.50", 38)],
            [("TOTAL", 0), ("1.50", 38)],
        ]
    )
    lines = [_priced(merged, 1), _priced(merged, 2), _priced(merged, 3)]
    return merged, lines


class TestReceiptFromLabels:
    def test_discount_attaches_to_previous_item(self):
        merged, lines = _setup()
        receipt = receipt_from_labels(merged, lines, [ITEM, DISCOUNT, TOTAL])
        assert [(i.amount, i.discount) for i in receipt.items] == [(2.0, 0.5)]
        assert receipt.total == 1.5 and receipt.checksum_ok

    def test_negative_price_labelled_item_becomes_a_discount(self):
        merged, lines = _setup()
        receipt = receipt_from_labels(merged, lines, [ITEM, ITEM, TOTAL])
        assert [(i.amount, i.discount) for i in receipt.items] == [(2.0, 0.5)]

    def test_no_items_returns_none(self):
        merged, lines = _setup()
        assert receipt_from_labels(merged, lines, [IGNORE, IGNORE, TOTAL]) is None


class TestReferenceTotal:
    def test_virtual_reference_fills_a_missing_total(self):
        merged, lines = _setup()
        receipt = receipt_from_labels(
            merged, lines, [ITEM, DISCOUNT, IGNORE], reference_total=1.5
        )
        assert receipt.total == 1.5 and receipt.checksum_ok

    def test_labelled_total_wins_over_the_reference(self):
        merged, lines = _setup()
        receipt = receipt_from_labels(
            merged, lines, [ITEM, DISCOUNT, TOTAL], reference_total=9.99
        )
        assert receipt.total == 1.5


class TestSingleItemReceipt:
    def test_one_item_named_after_the_store(self):
        from reference.structure_ml import single_item_receipt

        merged, _ = _setup()
        receipt = single_item_receipt(merged, 14.7)
        assert [(i.name, i.amount, i.discount) for i in receipt.items] == [
            ("STORE", 14.7, 0.0)
        ]
        assert receipt.total == 14.7 and receipt.checksum_ok


class TestConstrainedLabels:
    def test_forced_ignore_and_ineligible_totals_are_dropped(self):
        from reference.invariants import Constraints
        from reference.structure_ml import constrained_labels

        structure = Constraints(
            forced_ignore=frozenset({1}),
            reference_ranks=frozenset({3}),
            evidences=(),
        )
        labels = [ITEM, ITEM, TOTAL, TOTAL]
        assert constrained_labels(labels, structure) == [ITEM, IGNORE, IGNORE, TOTAL]
