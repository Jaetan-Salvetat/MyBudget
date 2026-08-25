from test_structure import receipt_lines

from reference.line_features import featurize
from reference.structure import merge_price_fragments
from truth.roles import (
    CHANGE,
    DISCOUNT,
    DISCOUNT_SUMMARY,
    IGNORE,
    ITEM,
    PAYMENT,
    QUANTITY,
    SUBTOTAL,
    TOTAL,
    TVA,
    line_truth,
)


def golden(items, total, discounts=None):
    discounts = discounts or {}
    return {
        "receipt": {
            "total": total,
            "items": [
                {"name": name, "amount": amount, "discount": discounts.get(name, 0)}
                for name, amount in items
            ],
        }
    }


def roles(rows, gold):
    merged = [merge_price_fragments(line) for line in receipt_lines(rows)]
    lines, _ = featurize(merged)
    return [(t.text.split()[0], t.role) for t in line_truth(merged, lines, gold)]


class TestLineTruth:
    def test_items_total_payment(self):
        rows = [
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("LAIT", 0), ("1,20", 38)],
            [("TOTAL", 0), ("3,70", 38)],
            [("CB", 0), ("3,70", 38)],
        ]
        assert roles(rows, golden([("PAIN", 2.5), ("LAIT", 1.2)], 3.7)) == [
            ("PAIN", ITEM),
            ("LAIT", ITEM),
            ("TOTAL", TOTAL),
            ("CB", PAYMENT),
        ]

    def test_single_item_equal_to_total_is_still_an_item(self):
        rows = [
            [("STORE", 10)],
            [("MENU", 0), ("7,35", 38)],
            [("ESPECES", 0), ("10,00", 38)],
            [("A", 0), ("RENDRE", 2), ("2,65", 38)],
            [("B", 0), ("20,00%", 2), ("6,13", 12), ("1,22", 20), ("7,35", 38)],
        ]
        assert roles(rows, golden([("MENU", 7.35)], 7.35)) == [
            ("MENU", ITEM),
            ("ESPECES", PAYMENT),
            ("A", CHANGE),
            ("B", TVA),
        ]

    def test_discount_and_summary(self):
        rows = [
            [("STORE", 10)],
            [("JEAN", 0), ("34,99", 38)],
            [("REMISE", 0), ("-17,50", 38)],
            [("PULL", 0), ("10,00", 38)],
            [("REMISE", 0), ("-2,50", 38)],
            [("TOTAL", 0), ("REMISES", 6), ("-20,00", 38)],
            [("TOTAL", 0), ("24,99", 38)],
        ]
        gold = golden(
            [("JEAN", 34.99), ("PULL", 10.0)], 24.99, {"JEAN": 17.5, "PULL": 2.5}
        )
        assert roles(rows, gold) == [
            ("JEAN", ITEM),
            ("REMISE", DISCOUNT),
            ("PULL", ITEM),
            ("REMISE", DISCOUNT),
            ("TOTAL", DISCOUNT_SUMMARY),
            ("TOTAL", TOTAL),
        ]

    def test_quantity_line_subtotal_and_noise(self):
        rows = [
            [("STORE", 10)],
            [("POMMES", 0)],
            [("3", 0), ("X", 2), ("1,00", 4), ("3,00", 38)],
            [("SOUS-TOTAL", 0), ("3,00", 38)],
            [("TEL", 0), ("05.46", 4), ("12,34", 38)],
            [("TOTAL", 0), ("3,00", 38)],
        ]
        assert roles(rows, golden([("POMMES", 3.0)], 3.0)) == [
            ("3", ITEM),
            ("SOUS-TOTAL", SUBTOTAL),
            ("TEL", IGNORE),
            ("TOTAL", TOTAL),
        ]

    def test_item_keeps_golden_name(self):
        rows = [
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("TOTAL", 0), ("2,50", 38)],
        ]
        merged = [merge_price_fragments(line) for line in receipt_lines(rows)]
        lines, _ = featurize(merged)
        truths = line_truth(merged, lines, golden([("PAIN COMPLET", 2.5)], 2.5))
        assert truths[0].golden_name == "PAIN COMPLET"
        assert truths[1].golden_name is None

    def test_quantity_line_role_when_amount_absent_from_golden(self):
        rows = [
            [("STORE", 10)],
            [("2", 0), ("X", 2), ("1,50", 4), ("9,99", 38)],
            [("TOTAL", 0), ("3,00", 38)],
        ]
        assert roles(rows, golden([("X", 3.0)], 3.0)) == [
            ("2", QUANTITY),
            ("TOTAL", TOTAL),
        ]
