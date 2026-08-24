import math

from lines import PhysicalLine, Word, cluster_lines, deskew_words
from structure import extract, merge_price_fragments, parse_price

LINE_HEIGHT = 30.0
CHAR_WIDTH = 14.0


def word(text: str, column: int, row: int) -> Word:
    left = column * CHAR_WIDTH
    top = row * (LINE_HEIGHT + 8)
    return Word(
        text=text,
        left=left,
        top=top,
        right=left + len(text) * CHAR_WIDTH,
        bottom=top + LINE_HEIGHT,
        confidence=0.9,
    )


def line(row: int, *tokens: tuple[str, int]) -> PhysicalLine:
    return PhysicalLine(words=[word(text, column, row) for text, column in tokens])


def receipt_lines(rows: list[list[tuple[str, int]]]) -> list[PhysicalLine]:
    return [line(index, *tokens) for index, tokens in enumerate(rows)]


class TestParsePrice:
    def test_comma_decimal(self):
        assert parse_price("12,50") == 12.50

    def test_dot_decimal(self):
        assert parse_price("3.99") == 3.99

    def test_negative(self):
        assert parse_price("-0,50") == -0.50

    def test_currency_suffix(self):
        assert parse_price("4,00€") == 4.00

    def test_leader_dots(self):
        assert parse_price("....14,90") == 14.90

    def test_rejects_plain_integer(self):
        assert parse_price("2016") is None

    def test_rejects_text(self):
        assert parse_price("TOTAL") is None


class TestExtract:
    def test_simple_items(self):
        lines = receipt_lines([
            [("CARREFOUR", 10)],
            [("LAIT", 0), ("ENTIER", 5), ("1,20", 38)],
            [("PAIN", 0), ("2,50", 38)],
            [("TOTAL", 0), ("3,70", 38)],
        ])
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [
            ("LAIT ENTIER", 1.20),
            ("PAIN", 2.50),
        ]
        assert result.total == 3.70
        assert result.checksum_ok

    def test_discount_attaches_to_previous_item(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("CHIPS", 0), ("2,00", 38)],
            [("REMISE", 2), ("FID.", 9), ("-0,50", 37)],
            [("TOTAL", 0), ("1,50", 38)],
        ])
        result = extract(lines)
        assert result.items[0].discount == 0.50
        assert result.checksum_ok

    def test_quantity_on_second_line(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("CAFE", 0), ("MOULU", 5)],
            [("3", 2), ("X", 4), ("3,40", 6), ("10,20", 37)],
            [("TOTAL", 0), ("10,20", 37)],
        ])
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [("CAFE MOULU", 10.20)]

    def test_total_and_payment_are_not_items(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("2,50", 38)],
            [("CB", 0), ("EMV", 3), ("2,50", 38)],
            [("ESPECES", 0), ("5,00", 38)],
            [("RENDU", 0), ("2,50", 38)],
        ])
        result = extract(lines)
        assert len(result.items) == 1
        assert result.total == 2.50

    def test_split_total_recovered(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("54,50", 37)],
            [("Total", 0), (":", 6), ("54", 37), ("50", 40)],
        ])
        result = extract(lines)
        assert result.total == 54.50

    def test_phone_number_is_not_a_price(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("Fax.:", 0), ("033", 6), ("853", 10), ("67", 14), ("19", 17)],
            [("PAIN", 0), ("2,50", 38)],
        ])
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [("PAIN", 2.50)]

    def test_date_with_split_digits(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("LE", 0), ("15/o9/202", 3), ("6", 13), ("A", 15), ("14:06", 17)],
        ])
        assert extract(lines).date == "2026-09-15"

    def test_date_with_dots(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("30.07.2007/13:29:17", 10)],
        ])
        assert extract(lines).date == "2007-07-30"

    def test_promotion_in_name_is_still_an_item(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("Salades", 0), ("x2", 8), ("(promotion)", 11), ("1,40", 38)],
            [("TOTAL", 0), ("1,40", 38)],
        ])
        result = extract(lines)
        assert result.items[0].amount == 1.40
        assert result.items[0].discount == 0.0

    def test_quantity_prefix_stripped_from_name(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("1", 0), ("WELSH", 2), ("10.20", 20), ("10.20", 37)],
        ])
        result = extract(lines)
        assert result.items[0].name == "WELSH"
        assert result.items[0].amount == 10.20


class TestMergePriceFragments:
    def test_split_discount_merged(self):
        source = line(0, ("REMISE", 2), ("-1,", 30), ("00", 33))
        merged = merge_price_fragments(source)
        assert [w.text for w in merged.words] == ["REMISE", "-1,00"]

    def test_distant_fragments_untouched(self):
        source = line(0, ("REMISE", 2), ("-1,", 10), ("00", 33))
        merged = merge_price_fragments(source)
        assert [w.text for w in merged.words] == ["REMISE", "-1,", "00"]


class TestDeskew:
    def test_rotated_words_regroup_on_same_line(self):
        left = word("PAIN", 0, 0)
        right = word("2,50", 38, 0)
        angle = 4.0
        radians = math.radians(angle)

        def rotate(w: Word) -> Word:
            cx, cy = (w.left + w.right) / 2, (w.top + w.bottom) / 2
            rx = cx * math.cos(radians) - cy * math.sin(radians)
            ry = cx * math.sin(radians) + cy * math.cos(radians)
            return Word(
                text=w.text,
                left=rx - (w.right - w.left) / 2,
                top=ry - (w.bottom - w.top) / 2,
                right=rx + (w.right - w.left) / 2,
                bottom=ry + (w.bottom - w.top) / 2,
                confidence=w.confidence,
            )

        tilted = [rotate(left), rotate(right)]
        assert len(cluster_lines(tilted)) == 2
        assert len(cluster_lines(deskew_words(tilted, angle))) == 1


class TestChangeDue:
    def test_a_rendre_line_is_not_an_item(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("ESPECES", 0), ("5,00", 38)],
            [("A", 0), ("RENDRE", 2), ("EUR", 20), ("2,50", 38)],
        ])
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [("PAIN", 2.50)]

    def test_a_rendre_zero_is_not_an_item(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("A", 0), ("RENDRE", 2), ("EUR", 20), ("0,00", 38)],
            [("TOTAL", 0), ("2,50", 38)],
        ])
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [("PAIN", 2.50)]
        assert result.checksum_ok


class TestExtraChecksumReferences:
    def test_tva_table_ttc_sum_validates_when_total_unreadable(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PERRIER", 0), ("3.20", 38)],
            [("CHARDONNAY", 0), ("6.80", 38)],
            [("TOTAL", 0), ("1O.0OO", 38)],
            [("B", 0), ("TUA", 2), ("20.00", 8), ("5.67", 15), ("1.13", 22), ("6.80", 38)],
            [("C", 0), ("TUA", 2), ("10.00", 8), ("2.91", 15), ("0.29", 22), ("3.20", 38)],
        ])
        result = extract(lines)
        assert result.total is None
        assert result.tva_ttc_sum == 10.00
        assert result.checksum_ok

    def test_tva_amount_only_lines_do_not_build_a_reference(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("TVA", 0), ("10%", 5), ("0,23", 38)],
        ])
        result = extract(lines)
        assert result.tva_ttc_sum is None

    def test_article_count_parsed(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("2", 0), ("ARTICLES", 2)],
        ])
        assert extract(lines).printed_count == 2

    def test_payment_with_matching_count_validates_despite_bad_total(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("LAIT", 0), ("1,20", 38)],
            [("TOTAL", 0), ("9,70", 38)],
            [("2", 0), ("ARTICLES", 2)],
            [("CB", 0), ("EMV", 4), ("3,70", 38)],
        ])
        result = extract(lines)
        assert result.total == 9.70
        assert result.checksum_ok

    def test_payment_without_count_does_not_override_read_total(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("LAIT", 0), ("1,20", 38)],
            [("TOTAL", 0), ("9,70", 38)],
            [("CB", 0), ("EMV", 4), ("3,70", 38)],
        ])
        assert not extract(lines).checksum_ok

    def test_count_mismatch_does_not_unlock_payment(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("PAIN", 0), ("2,50", 38)],
            [("LAIT", 0), ("1,20", 38)],
            [("TOTAL", 0), ("9,70", 38)],
            [("3", 0), ("ARTICLES", 2)],
            [("CB", 0), ("EMV", 4), ("3,70", 38)],
        ])
        assert not extract(lines).checksum_ok


class TestTotalRecovery:
    def test_abbreviated_tot_is_a_total(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("POMME", 0), ("1,32", 38)],
            [("ENDIVE", 0), ("2,42", 38)],
            [("2", 0), ("Art.", 2), ("Tot", 8), ("3,74", 38)],
        ])
        result = extract(lines)
        assert result.total == 3.74
        assert result.checksum_ok

    def test_tva_incl_total_is_not_excluded(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("MENU", 0), ("27,90", 38)],
            [("Total", 0), ("(TVA", 8), ("INCL)", 13), ("27,90", 38)],
        ])
        assert extract(lines).total == 27.90

    def test_missing_decimal_separator_total_rescued(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("MENU", 0), ("27,90", 38)],
            [("Total", 0), ("(TVA", 8), ("INCL)", 13), ("2790", 38)],
        ])
        result = extract(lines)
        assert result.checksum_ok

    def test_orphan_trailing_price_matching_sum_validates(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("Pomme", 0)],
            [("X", 2), ("2,60", 6), ("2,60", 38)],
            [("BANANE", 0), ("2,44", 38)],
            [("5,04", 38)],
            [("0,27", 38)],
        ])
        result = extract(lines)
        assert result.items_sum == 5.04
        assert result.checksum_ok

    def test_orphan_price_not_matching_sum_flags(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("BANANE", 0), ("2,44", 38)],
            [("9,99", 38)],
        ])
        result = extract(lines)
        assert not result.checksum_ok


class TestDiscountLeftOfColumn:
    def test_negative_price_escapes_column_filter(self):
        lines = receipt_lines([
            [("STORE", 10)],
            [("JEAN", 0)],
            [("*082242000033", 0), ("36", 15), ("34.99", 30), ("€", 37)],
            [("Action", 0), ("commerciale", 7), ("-50%=", 19), ("-17.50", 26), ("€", 34)],
            [("Total", 0), ("17.49", 30), ("€", 37)],
            [("Carte", 0), ("Bancaire", 6), ("17.49", 30)],
        ])
        result = extract(lines)
        assert [(i.name, i.amount, i.discount) for i in result.items] == [
            ("JEAN", 34.99, 17.50),
        ]
        assert result.checksum_ok
