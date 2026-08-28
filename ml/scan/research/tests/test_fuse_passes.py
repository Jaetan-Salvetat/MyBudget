from test_structure import line, receipt_lines

from reference.fuse_passes import FusedPass, fuse_passes


def texts(fused: FusedPass) -> list[str]:
    return [physical.text for physical in fused.lines]


class TestFusePasses:
    def test_identical_passes_keep_the_primary(self):
        primary = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("TOTAL", 0), ("2,50", 38)],
            ]
        )
        fused = fuse_passes(
            primary,
            receipt_lines(
                [
                    [("STORE", 10)],
                    [("PAIN", 0), ("2,50", 38)],
                    [("TOTAL", 0), ("2,50", 38)],
                ]
            ),
        )
        assert texts(fused) == ["STORE", "PAIN 2,50", "TOTAL 2,50"]
        assert fused.alternatives == {}

    def test_differing_amount_on_the_same_line_becomes_an_alternative(self):
        primary = receipt_lines(
            [
                [("STORE", 10)],
                [("TORT", 0), ("RICOTTA", 5), ("S2.75e", 36)],
                [("TOTAL", 0), ("2,75", 38)],
            ]
        )
        secondary = receipt_lines(
            [
                [("STORE", 10)],
                [("TORT", 0), ("RICOTTA", 5), ("2.75€", 36)],
                [("TOTAL", 0), ("2,75", 38)],
            ]
        )
        fused = fuse_passes(primary, secondary)
        assert texts(fused)[1] == "TORT RICOTTA S2.75e"
        assert fused.alternatives == {1: 275}

    def test_unpriced_primary_line_is_replaced_by_the_priced_secondary(self):
        primary = receipt_lines(
            [
                [("STORE", 10)],
                [("SALAD", 0), ("VENEZIA", 6), ("4.236", 36)],
                [("TOTAL", 0), ("4,23", 38)],
            ]
        )
        secondary = receipt_lines(
            [
                [("STORE", 10)],
                [("SALAD", 0), ("VENEZIA", 6), ("4.23€", 36)],
                [("TOTAL", 0), ("4,23", 38)],
            ]
        )
        fused = fuse_passes(primary, secondary)
        assert texts(fused) == ["STORE", "SALAD VENEZIA 4.23€", "TOTAL 4,23"]
        assert fused.alternatives == {}

    def test_secondary_only_line_is_inserted_in_reading_order(self):
        primary = [
            line(0, ("STORE", 10)),
            line(1, ("PAIN", 0), ("2,50", 38)),
            line(3, ("TOTAL", 0), ("3,70", 38)),
        ]
        secondary = [
            line(0, ("STORE", 10)),
            line(1, ("PAIN", 0), ("2,50", 38)),
            line(2, ("LAIT", 0), ("1,20", 38)),
            line(3, ("TOTAL", 0), ("3,70", 38)),
        ]
        fused = fuse_passes(primary, secondary)
        assert texts(fused) == ["STORE", "PAIN 2,50", "LAIT 1,20", "TOTAL 3,70"]

    def test_primary_line_holding_two_prices_is_split_by_the_secondary(self):
        primary = [
            line(0, ("STORE", 10)),
            line(1, ("KINDER", 0), ("LEFFE", 8), ("10.50€", 28), ("5.95€", 36)),
            line(2, ("TOTAL", 0), ("16,45", 38)),
        ]
        secondary = [
            line(0, ("STORE", 10)),
            line(0.8, ("KINDER", 0), ("5.95€", 36)),
            line(1.2, ("LEFFE", 0), ("10.50€", 36)),
            line(2, ("TOTAL", 0), ("16,45", 38)),
        ]
        fused = fuse_passes(primary, secondary)
        assert texts(fused) == ["STORE", "KINDER 5.95€", "LEFFE 10.50€", "TOTAL 16,45"]

    def test_secondary_line_far_from_any_primary_line_is_not_a_match(self):
        primary = [
            line(0, ("STORE", 10)),
            line(1, ("PAIN", 0), ("2,50", 38)),
        ]
        secondary = [
            line(0, ("STORE", 10)),
            line(1, ("PAIN", 0), ("2,60", 38)),
            line(4, ("TOTAL", 0), ("2,60", 38)),
        ]
        fused = fuse_passes(primary, secondary)
        assert texts(fused) == ["STORE", "PAIN 2,50", "TOTAL 2,60"]
        assert fused.alternatives == {1: 260}
