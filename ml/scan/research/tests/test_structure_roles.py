"""Les articles décidés par le tagger de rôles, pas par les règles.

Le tagger apprend la question « cette ligne est-elle un article ? » sur tout
le corpus ; les règles la déduisent de la géométrie et de lexiques. Ce module
teste la structuration une fois la décision prise — les rôles sont donnés,
pas prédits, pour que le test ne mesure que la mise en reçu.
"""

from __future__ import annotations

from annotate.schema import (
    DISCOUNT,
    FOOTER,
    HEADER,
    ITEM,
    ITEM_LABEL,
    NOISE,
    PAYMENT,
    SUBTOTAL,
    TOTAL,
)
from reference.structure import merge_price_fragments
from reference.structure_roles import extract_roles

from test_structure import receipt_lines


def receipt_of(rows, roles):
    lines = [merge_price_fragments(line) for line in receipt_lines(rows)]
    return extract_roles(lines, roles)


class TestExtractRoles:
    def test_items_and_discount(self):
        receipt = receipt_of(
            [
                [("CARREFOUR", 10)],
                [("LAIT", 0), ("ENTIER", 5), ("1,20", 38)],
                [("REMISE", 0), ("-0,20", 38)],
                [("TOTAL", 0), ("1,00", 38)],
            ],
            [HEADER, ITEM, DISCOUNT, TOTAL],
        )
        assert [(i.name, i.amount, i.discount) for i in receipt.items] == [
            ("LAIT ENTIER", 1.20, 0.20)
        ]
        assert receipt.total == 1.00
        assert receipt.checksum_ok

    def test_a_priced_line_the_tagger_rejects_is_not_an_item(self):
        """Le prix unitaire imprimé seul : le tagger le dit `noise`, il ne
        devient pas un article — c'est exactement ce que les règles ratent."""
        receipt = receipt_of(
            [
                [("MAXI", 10)],
                [("1", 8), ("x", 11), ("16,99", 24), ("EUR", 32)],
                [
                    ("PREM", 0),
                    ("Litiere", 6),
                    ("AGGLO", 15),
                    ("12KG", 22),
                    ("16,99", 30),
                    ("D", 38),
                ],
                [("Reduction", 0), ("-4,49", 30)],
                [("TOTAL", 0), ("12,50", 30)],
            ],
            [HEADER, NOISE, ITEM, DISCOUNT, TOTAL],
        )
        assert [(i.name, i.amount, i.discount) for i in receipt.items] == [
            ("PREM Litiere AGGLO 12KG", 16.99, 4.49)
        ]
        assert receipt.checksum_ok

    def test_label_printed_above_its_price(self):
        receipt = receipt_of(
            [
                [("PRIMEURS", 10)],
                [("POIRE", 0), ("CONFERENCE", 6)],
                [("0,792", 0), ("kg", 6), ("2,65", 12), ("EUR/kg", 17), ("2,10", 38)],
                [("TOTAL", 0), ("2,10", 38)],
            ],
            [HEADER, ITEM_LABEL, ITEM, TOTAL],
        )
        assert [i.name for i in receipt.items] == ["POIRE CONFERENCE"]
        assert receipt.checksum_ok

    def test_payment_and_subtotal_are_references_not_items(self):
        receipt = receipt_of(
            [
                [("STORE", 10)],
                [("VESTE", 0), ("34,99", 38)],
                [("SOUS-TOTAL", 0), ("34,99", 38)],
                [("CB", 0), ("34,99", 38)],
                [("MERCI", 10)],
            ],
            [HEADER, ITEM, SUBTOTAL, PAYMENT, FOOTER],
        )
        assert [i.amount for i in receipt.items] == [34.99]
        assert receipt.subtotal == 34.99
        assert receipt.payment == 34.99
        assert receipt.checksum_ok

    def test_a_negative_amount_is_never_an_item(self):
        """Le tagger peut se tromper de rôle ; un article négatif, jamais."""
        receipt = receipt_of(
            [
                [("STORE", 10)],
                [("VESTE", 0), ("34,99", 38)],
                [("AVANTAGE", 0), ("-4,99", 38)],
                [("TOTAL", 0), ("30,00", 38)],
            ],
            [HEADER, ITEM, ITEM, TOTAL],
        )
        assert [(i.amount, i.discount) for i in receipt.items] == [(34.99, 4.99)]
        assert receipt.checksum_ok

    def test_no_item_yields_nothing(self):
        assert (
            receipt_of(
                [[("STORE", 10)], [("TOTAL", 0), ("1,00", 38)]],
                [HEADER, TOTAL],
            )
            is None
        )
