import math

from reference.lines import PhysicalLine, Word, cluster_lines, deskew_words
from reference.structure import extract, merge_price_fragments, parse_price

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
        lines = receipt_lines(
            [
                [("CARREFOUR", 10)],
                [("LAIT", 0), ("ENTIER", 5), ("1,20", 38)],
                [("PAIN", 0), ("2,50", 38)],
                [("TOTAL", 0), ("3,70", 38)],
            ]
        )
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [
            ("LAIT ENTIER", 1.20),
            ("PAIN", 2.50),
        ]
        assert result.total == 3.70
        assert result.checksum_ok

    def test_discount_attaches_to_previous_item(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("CHIPS", 0), ("2,00", 38)],
                [("REMISE", 2), ("FID.", 9), ("-0,50", 37)],
                [("TOTAL", 0), ("1,50", 38)],
            ]
        )
        result = extract(lines)
        assert result.items[0].discount == 0.50
        assert result.checksum_ok

    def test_quantity_on_second_line(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("CAFE", 0), ("MOULU", 5)],
                [("3", 2), ("X", 4), ("3,40", 6), ("10,20", 37)],
                [("TOTAL", 0), ("10,20", 37)],
            ]
        )
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [("CAFE MOULU", 10.20)]

    def test_total_and_payment_are_not_items(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("2,50", 38)],
                [("CB", 0), ("EMV", 3), ("2,50", 38)],
                [("ESPECES", 0), ("5,00", 38)],
                [("RENDU", 0), ("2,50", 38)],
            ]
        )
        result = extract(lines)
        assert len(result.items) == 1
        assert result.total == 2.50

    def test_split_total_recovered(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("54,50", 37)],
                [("Total", 0), (":", 6), ("54", 37), ("50", 40)],
            ]
        )
        result = extract(lines)
        assert result.total == 54.50

    def test_phone_number_is_not_a_price(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("Fax.:", 0), ("033", 6), ("853", 10), ("67", 14), ("19", 17)],
                [("PAIN", 0), ("2,50", 38)],
            ]
        )
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [("PAIN", 2.50)]

    def test_date_with_split_digits(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("LE", 0), ("15/o9/202", 3), ("6", 13), ("A", 15), ("14:06", 17)],
            ]
        )
        assert extract(lines).date == "2026-09-15"

    def test_date_with_dots(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("30.07.2007/13:29:17", 10)],
            ]
        )
        assert extract(lines).date == "2007-07-30"

    def test_promotion_in_name_is_still_an_item(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("Salades", 0), ("x2", 8), ("(promotion)", 11), ("1,40", 38)],
                [("TOTAL", 0), ("1,40", 38)],
            ]
        )
        result = extract(lines)
        assert result.items[0].amount == 1.40
        assert result.items[0].discount == 0.0

    def test_quantity_prefix_stripped_from_name(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("1", 0), ("WELSH", 2), ("10.20", 20), ("10.20", 37)],
            ]
        )
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
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("ESPECES", 0), ("5,00", 38)],
                [("A", 0), ("RENDRE", 2), ("EUR", 20), ("2,50", 38)],
            ]
        )
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [("PAIN", 2.50)]

    def test_a_rendre_zero_is_not_an_item(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("A", 0), ("RENDRE", 2), ("EUR", 20), ("0,00", 38)],
                [("TOTAL", 0), ("2,50", 38)],
            ]
        )
        result = extract(lines)
        assert [(i.name, i.amount) for i in result.items] == [("PAIN", 2.50)]
        assert result.checksum_ok


class TestExtraChecksumReferences:
    def test_tva_table_ttc_sum_validates_when_total_unreadable(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PERRIER", 0), ("3.20", 38)],
                [("CHARDONNAY", 0), ("6.80", 38)],
                [("TOTAL", 0), ("1O.0OO", 38)],
                [
                    ("B", 0),
                    ("TUA", 2),
                    ("20.00", 8),
                    ("5.67", 15),
                    ("1.13", 22),
                    ("6.80", 38),
                ],
                [
                    ("C", 0),
                    ("TUA", 2),
                    ("10.00", 8),
                    ("2.91", 15),
                    ("0.29", 22),
                    ("3.20", 38),
                ],
            ]
        )
        result = extract(lines)
        assert result.total is None
        assert result.tva_ttc_sum == 10.00
        assert result.checksum_ok

    def test_tva_amount_only_lines_do_not_build_a_reference(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("TVA", 0), ("10%", 5), ("0,23", 38)],
            ]
        )
        result = extract(lines)
        assert result.tva_ttc_sum is None

    def test_article_count_parsed(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("2", 0), ("ARTICLES", 2)],
            ]
        )
        assert extract(lines).printed_count == 2

    def test_payment_with_matching_count_validates_despite_bad_total(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("LAIT", 0), ("1,20", 38)],
                [("TOTAL", 0), ("9,70", 38)],
                [("2", 0), ("ARTICLES", 2)],
                [("CB", 0), ("EMV", 4), ("3,70", 38)],
            ]
        )
        result = extract(lines)
        assert result.total == 9.70
        assert result.checksum_ok

    def test_payment_without_count_does_not_override_read_total(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("LAIT", 0), ("1,20", 38)],
                [("TOTAL", 0), ("9,70", 38)],
                [("CB", 0), ("EMV", 4), ("3,70", 38)],
            ]
        )
        assert not extract(lines).checksum_ok

    def test_count_mismatch_does_not_unlock_payment(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("PAIN", 0), ("2,50", 38)],
                [("LAIT", 0), ("1,20", 38)],
                [("TOTAL", 0), ("9,70", 38)],
                [("3", 0), ("ARTICLES", 2)],
                [("CB", 0), ("EMV", 4), ("3,70", 38)],
            ]
        )
        assert not extract(lines).checksum_ok


class TestTotalRecovery:
    def test_abbreviated_tot_is_a_total(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("POMME", 0), ("1,32", 38)],
                [("ENDIVE", 0), ("2,42", 38)],
                [("2", 0), ("Art.", 2), ("Tot", 8), ("3,74", 38)],
            ]
        )
        result = extract(lines)
        assert result.total == 3.74
        assert result.checksum_ok

    def test_tva_incl_total_is_not_excluded(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("MENU", 0), ("27,90", 38)],
                [("Total", 0), ("(TVA", 8), ("INCL)", 13), ("27,90", 38)],
            ]
        )
        assert extract(lines).total == 27.90

    def test_missing_decimal_separator_total_rescued(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("MENU", 0), ("27,90", 38)],
                [("Total", 0), ("(TVA", 8), ("INCL)", 13), ("2790", 38)],
            ]
        )
        result = extract(lines)
        assert result.checksum_ok

    def test_orphan_trailing_price_matching_sum_validates(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("Pomme", 0)],
                [("X", 2), ("2,60", 6), ("2,60", 38)],
                [("BANANE", 0), ("2,44", 38)],
                [("5,04", 38)],
                [("0,27", 38)],
            ]
        )
        result = extract(lines)
        assert result.items_sum == 5.04
        assert result.checksum_ok

    def test_orphan_price_not_matching_sum_flags(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("BANANE", 0), ("2,44", 38)],
                [("9,99", 38)],
            ]
        )
        result = extract(lines)
        assert not result.checksum_ok


class TestDiscountLeftOfColumn:
    def test_negative_price_escapes_column_filter(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("JEAN", 0)],
                [("*082242000033", 0), ("36", 15), ("34.99", 30), ("€", 37)],
                [
                    ("Action", 0),
                    ("commerciale", 7),
                    ("-50%=", 19),
                    ("-17.50", 26),
                    ("€", 34),
                ],
                [("Total", 0), ("17.49", 30), ("€", 37)],
                [("Carte", 0), ("Bancaire", 6), ("17.49", 30)],
            ]
        )
        result = extract(lines)
        assert [(i.name, i.amount, i.discount) for i in result.items] == [
            ("JEAN", 34.99, 17.50),
        ]
        assert result.checksum_ok


class TestPaymentSynonyms:
    def _receipt(self, payment_row):
        return receipt_lines(
            [
                [("STORE", 10)],
                [("POMME", 0), ("1,32", 38)],
                [("ENDIVE", 0), ("2,42", 38)],
                payment_row,
            ]
        )

    def test_cash_line_is_a_payment_reference(self):
        result = extract(self._receipt([("Espèces", 0), ("3,74", 38)]))
        assert result.payment == 3.74
        assert (
            result.items == [result.items[0], result.items[1]]
            and len(result.items) == 2
        )
        assert result.checksum_ok

    def test_cheque_line_is_a_payment_reference(self):
        result = extract(self._receipt([("CHEQUE", 0), ("AUTO.", 8), ("3,74", 38)]))
        assert result.payment == 3.74
        assert result.checksum_ok

    def test_paiement_line_is_a_payment_reference(self):
        result = extract(self._receipt([("Paiement", 0), ("CB", 10), ("3,74", 38)]))
        assert result.payment == 3.74
        assert result.checksum_ok

    def test_montant_percu_is_a_payment_reference(self):
        result = extract(
            self._receipt([("Montant", 0), ("perçu", 8), (":", 14), ("3,74", 38)])
        )
        assert result.payment == 3.74
        assert result.checksum_ok

    def test_payment_never_overrides_a_read_total(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("POMME", 0), ("1,32", 38)],
                [("TOTAL", 0), ("9,99", 38)],
                [("Espèces", 0), ("1,32", 38)],
            ]
        )
        result = extract(lines)
        assert result.total == 9.99
        assert not result.checksum_ok


class TestTotalSynonyms:
    def _receipt(self, total_row):
        return receipt_lines(
            [
                [("STORE", 10)],
                [("POMME", 0), ("1,32", 38)],
                [("ENDIVE", 0), ("2,42", 38)],
                total_row,
            ]
        )

    def test_net_a_regler(self):
        result = extract(
            self._receipt([("NET", 0), ("A", 4), ("REGLER", 6), ("3,74", 38)])
        )
        assert result.total == 3.74
        assert result.checksum_ok

    def test_doit(self):
        result = extract(self._receipt([("DOIT", 0), ("3,74", 38)]))
        assert result.total == 3.74
        assert result.checksum_ok

    def test_prix_ttc(self):
        result = extract(self._receipt([("PRIX", 0), ("TTC", 5), ("3,74", 38)]))
        assert result.total == 3.74
        assert result.checksum_ok

    def test_montant_ttc(self):
        result = extract(self._receipt([("Montant", 0), ("TTC", 8), ("3,74", 38)]))
        assert result.total == 3.74
        assert result.checksum_ok


class TestDamagedPrices:
    def test_semicolon_decimal_separator(self):
        assert parse_price("17;00") == 17.00

    def test_leading_colon_stripped(self):
        assert parse_price(":17,00") == 17.00

    def test_total_line_price_with_trailing_junk_digit(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("SALADE", 0), ("7,07", 38)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("7.074", 37)],
            ]
        )
        assert extract(lines).total == 7.07

    def test_item_line_keeps_three_decimals_unparsed(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("SALADE", 0), ("4.236", 38)],
                [("TOTAL", 0), ("4,23", 38)],
            ]
        )
        assert extract(lines).items == []

    def test_split_total_with_separator_on_decimals(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("VIN", 0), ("17,00", 38)],
                [("TOTAL", 0), ("TTC", 6), ("17", 36), (",00", 38)],
            ]
        )
        assert extract(lines).total == 17.00


class TestFuzzyTotal:
    def test_total_with_one_damaged_glyph(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("CLOU", 0), ("32,17", 38)],
                [("TO'AL", 0), ("Euro", 6), ("32.17", 38)],
            ]
        )
        result = extract(lines)
        assert result.total == 32.17
        assert result.checksum_ok

    def test_total_missing_first_letter(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("VIN", 0), ("14,50", 38)],
                [("OTAL", 0), ("REGLEMENT", 5), ("14,50", 38)],
            ]
        )
        assert extract(lines).total == 14.50

    def test_unrelated_word_is_not_a_total(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("HOTEL", 0), ("DU", 6), ("PORT", 9), ("80,00", 38)],
                [("TOTAL", 0), ("80,00", 38)],
            ]
        )
        result = extract(lines)
        assert [i.amount for i in result.items] == [80.00]


class TestSubtotalAbbreviation:
    def test_s_tot_is_a_subtotal_never_the_total(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("CAFE", 0), ("4,35", 38)],
                [("S/TOT", 0), ("18.47", 38)],
                [("TOTAL", 0), ("4,35", 38)],
            ]
        )
        result = extract(lines)
        assert result.total == 4.35
        assert result.subtotal == 18.47

    def test_s_tot_alone_does_not_become_the_total(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("CAFE", 0), ("4,35", 38)],
                [("S/TOT", 0), ("18.47", 38)],
            ]
        )
        assert extract(lines).total is None


class TestCardBrandPayments:
    def test_visa_line_is_a_payment(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("JEU", 0), ("38,96", 38)],
                [("Visa", 0), ("38.96", 38)],
            ]
        )
        result = extract(lines)
        assert result.payment == 38.96
        assert len(result.items) == 1

    def test_contactless_line_is_a_payment(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("JEU", 0), ("7,07", 38)],
                [("C8", 0), ("EMV", 3), ("SANS", 7), ("CONTACT", 12), ("7.07", 38)],
            ]
        )
        result = extract(lines)
        assert result.payment == 7.07
        assert len(result.items) == 1


class TestVerifiedTotal:
    def _receipt(self, **overrides):
        from reference.structure import ExtractedItem, ExtractedReceipt

        fields = {
            "store": None,
            "date": None,
            "total": None,
            "subtotal": None,
            "payment": None,
            "items": [ExtractedItem(name="A", amount=2.0, discount=0.0)],
        }
        fields.update(overrides)
        return ExtractedReceipt(**fields)

    def test_read_total_that_matches(self):
        assert self._receipt(total=2.0).verified_total == 2.0

    def test_payment_with_count_overrides_a_misread_total(self):
        receipt = self._receipt(total=3.44, payment=2.0, printed_count=1)
        assert receipt.checksum_ok
        assert receipt.verified_total == 2.0

    def test_tva_table_sum_when_total_unreadable(self):
        receipt = self._receipt(tva_ttc_sum=2.0)
        assert receipt.verified_total == 2.0

    def test_none_when_nothing_matches(self):
        assert self._receipt(total=9.0).verified_total is None


class TestTaxLexicon:
    def test_us_tax_line_is_not_an_item(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("BURGER", 0), ("8,95", 38)],
                [("TAX", 0), ("0,74", 38)],
                [("TOTAL", 0), ("9,69", 38)],
            ]
        )
        assert [i.amount for i in extract(lines).items] == [8.95]


class TestZeroAmountLines:
    def test_zero_amount_line_is_not_an_item(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("VESTE", 0), ("34,99", 38)],
                [("Info", 0), ("0,00", 38)],
                [("TOTAL", 0), ("34,99", 38)],
            ]
        )
        assert [i.amount for i in extract(lines).items] == [34.99]



class TestLabelColumn:
    """Le libellé est la zone de gauche du ticket, pas le résidu d'une
    soustraction. Les colonnes de droite — devise, classe de TVA, quantité —
    n'en font jamais partie, et une ligne dont la zone de gauche ne porte pas
    de mot n'est pas un article."""

    def test_vat_class_letter_is_not_part_of_the_name(self):
        lines = receipt_lines(
            [
                [("MAXI", 10)],
                [("SAFE", 0), ("Maison", 5), ("toil", 12), ("399,00", 30), ("D", 38)],
                [("Reduction", 0), ("-50,00", 30)],
                [("TOTAL", 0), ("349,00", 30)],
            ]
        )
        result = extract(lines)
        assert [(i.name, i.amount, i.discount) for i in result.items] == [
            ("SAFE Maison toil", 399.00, 50.00),
        ]
        assert result.checksum_ok

    def test_vat_class_digit_is_not_part_of_the_name(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [("EMMENTAL", 0), ("RAPE", 9), ("1.22", 30), ("2", 38)],
                [("POMME", 0), ("ROYAL", 6), ("GALA", 12), ("3.58", 30), ("2", 38)],
                [("TOTAL", 0), ("4.80", 30)],
            ]
        )
        result = extract(lines)
        assert [i.name for i in result.items] == ["EMMENTAL RAPE", "POMME ROYAL GALA"]
        assert result.checksum_ok

    def test_unit_price_row_names_no_article(self):
        """Maxi Zoo, Zooplus, jardineries : le prix unitaire est imprime seul
        au-dessus du nom, et le montant se retrouve sur deux lignes. Celle qui
        n'a que la quantite a gauche ne nomme rien — elle ne peut plus
        produire « x EUR ». Decider qu'elle n'est pas un article demande de
        savoir si le libelle du dessus en est un : c'est le tagger de roles
        qui tranche, pas la colonne."""
        lines = receipt_lines(
            [
                [("MAXI", 10)],
                [("1", 8), ("x", 11), ("16,99", 24), ("EUR", 32)],
                [("Art/Ean", 0), ("4047777102236", 8)],
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
            ]
        )
        names = [i.name for i in extract(lines).items]
        assert "PREM Litiere AGGLO 12KG" in names
        assert not any("EUR" in name for name in names)

    def test_name_spanning_the_left_zone_is_kept_whole(self):
        lines = receipt_lines(
            [
                [("STORE", 10)],
                [
                    ("CHOCO", 0),
                    ("EXCELLENCE", 6),
                    ("NR", 17),
                    ("85%", 20),
                    ("LINDT", 24),
                    ("1.19", 30),
                    ("2", 38),
                ],
                [("TOTAL", 0), ("1.19", 30)],
            ]
        )
        assert [i.name for i in extract(lines).items] == [
            "CHOCO EXCELLENCE NR 85% LINDT"
        ]
