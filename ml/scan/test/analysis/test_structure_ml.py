from line_features import PricedLine
from structure_ml import DISCOUNT, IGNORE, ITEM, TOTAL, receipt_from_labels
from test_structure import receipt_lines


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
