from test_structure import receipt_lines

from reference.invariants import (
    PAYMENT_CHANGE,
    TAX,
    TOTAL_LINE,
    Constraints,
    _last_total_rank,
    constraints,
    payment_change_evidence,
    reference_ranks,
    summary_discount_ranks,
    tax_evidence,
)
from reference.line_features import priced_lines


def priced(rows):
    return priced_lines(receipt_lines(rows))


class TestTaxEvidence:
    def test_ht_line_plus_tva_line_proves_the_ttc(self):
        lines = priced(
            [
                [("CAFE", 0), ("4.50", 38)],
                [("CHOCOLAT", 0), ("5.80", 38)],
                [("TVA", 0), ("10%", 4), ("0.94", 38)],
                [("HT", 0), ("9.36", 38)],
                [("10.30", 38)],
            ]
        )
        evidence, ignored = tax_evidence(lines)
        assert evidence is not None
        assert evidence.cents == 1030
        assert evidence.source == TAX
        assert evidence.cutoff_rank == 2
        assert ignored == {2, 3}

    def test_multi_rate_decomposition_sums_the_ttc(self):
        lines = priced(
            [
                [("PDJ", 0), ("2.40", 38)],
                [("0.12", 0), ("TVA", 5), ("10%", 9), ("1.32", 38)],
                [("TTL", 0), ("Net", 4), ("1.20", 38)],
                [("0.06", 0), ("TVA", 5), ("5.5%", 9), ("1.08", 38)],
                [("TTL", 0), ("Net", 4), ("1.02", 38)],
            ]
        )
        evidence, ignored = tax_evidence(lines)
        assert evidence.cents == 240
        assert ignored == {1, 2, 3, 4}

    def test_tva_table_row_proves_its_ttc(self):
        lines = priced(
            [
                [("PEINTURE", 0), ("7,35", 38)],
                [("B", 0), ("20,00%", 2), ("6,13", 20), ("1,22", 28), ("7,35", 38)],
            ]
        )
        evidence, ignored = tax_evidence(lines)
        assert evidence.cents == 735
        assert ignored == {1}

    def test_rate_shaped_row_without_lexicon_is_a_tax_row(self):
        lines = priced(
            [
                [("1", 0), ("29.99", 10), ("29.99", 30), ("A", 38)],
                [("A", 0), ("20.00", 4), ("24.99", 20), ("5.00", 38)],
            ]
        )
        evidence, ignored = tax_evidence(lines)
        assert evidence.cents == 2999
        assert ignored == {1}

    def test_item_matching_the_rate_is_not_taken_as_ht(self):
        lines = priced(
            [
                [("BIERE", 0), ("5.00", 38)],
                [("TVA", 0), ("20%", 4), ("1.00", 38)],
                [("TOTAL", 0), ("6.00", 38)],
            ]
        )
        evidence, ignored = tax_evidence(lines)
        assert evidence is None
        assert ignored == set()

    def test_tva_amount_only_without_partner_gives_nothing(self):
        lines = priced(
            [
                [("PAIN", 0), ("2.50", 38)],
                [("Dont", 0), ("TVA", 5), ("0.13", 38)],
            ]
        )
        evidence, ignored = tax_evidence(lines)
        assert evidence is None
        assert ignored == set()


class TestPaymentChangeEvidence:
    def test_cash_minus_change(self):
        lines = priced(
            [
                [("PEINTURE", 0), ("7,35", 38)],
                [("ESPECES", 0), ("10,00", 38)],
                [("A", 0), ("RENDRE", 2), ("2,65", 38)],
            ]
        )
        evidence = payment_change_evidence(lines)
        assert evidence.cents == 735
        assert evidence.source == PAYMENT_CHANGE
        assert evidence.cutoff_rank == 1

    def test_change_line_naming_cash_is_not_a_payment(self):
        lines = priced(
            [
                [("SOUPE", 0), ("7,98", 38)],
                [("Espèces", 0), ("20,00", 38)],
                [("Rendu", 0), ("Espèces", 6), ("4,04", 38)],
            ]
        )
        assert payment_change_evidence(lines).cents == 1596

    def test_largest_payment_before_the_change_is_the_cash_given(self):
        lines = priced(
            [
                [("PDJ", 0), ("2.40", 38)],
                [("Especes", 0), ("3.00", 38)],
                [("Reglement", 0), ("2.40", 38)],
                [("A", 0), ("Rendre", 2), ("0.60", 38)],
            ]
        )
        assert payment_change_evidence(lines).cents == 240

    def test_negative_change_amount(self):
        lines = priced(
            [
                [("SAUCISSON", 0), ("4.79", 38)],
                [("ESPECES", 0), ("EUR", 8), ("5.00", 38)],
                [("Votre", 0), ("Monnaie", 6), ("-0.21", 37)],
            ]
        )
        assert payment_change_evidence(lines).cents == 479

    def test_no_change_line_gives_nothing(self):
        lines = priced(
            [
                [("PAIN", 0), ("2.50", 38)],
                [("ESPECES", 0), ("2.50", 38)],
            ]
        )
        assert payment_change_evidence(lines) is None


class TestSummaryDiscounts:
    def test_single_discount_recapped_with_total_word(self):
        lines = priced(
            [
                [("LIT", 0), ("55,00", 38)],
                [("Nouveau", 0), ("prix", 8), ("49,90", 14), ("-5,10", 37)],
                [("SOUS", 0), ("TOTAL", 5), ("66,37", 38)],
                [("REMISE", 0), ("TOTALE", 7), ("-5,10", 37)],
                [("TOTAL", 0), ("61,27", 38)],
            ]
        )
        assert summary_discount_ranks(lines) == {3}

    def test_two_discounts_recapped_by_their_sum(self):
        lines = priced(
            [
                [("OEUFS", 0), ("6,20", 38)],
                [("50", 0), ("%", 3), ("PAQUES", 5), ("-1,55", 37)],
                [("50", 0), ("%", 3), ("PAQUES", 5), ("-1,55", 37)],
                [("REMISE", 0), ("TTALE", 7), ("-3,10", 37)],
                [("TOTAL", 0), ("3,10", 38)],
            ]
        )
        assert summary_discount_ranks(lines) == {3}

    def test_identical_real_discounts_are_not_summaries(self):
        lines = priced(
            [
                [("OEUFS", 0), ("6,20", 38)],
                [("50", 0), ("%", 3), ("PAQUES", 5), ("-1,55", 37)],
                [("50", 0), ("%", 3), ("PAQUES", 5), ("-1,55", 37)],
                [("TOTAL", 0), ("3,10", 38)],
            ]
        )
        assert summary_discount_ranks(lines) == set()

    def test_total_before_discounts_line_is_never_a_real_discount(self):
        lines = priced(
            [
                [("OREILLER", 0), ("11,90", 38)],
                [("Remise", 0), ("Immédiate", 7), ("11,90", 38)],
                [("TOTAL", 0), ("AVANT", 6), ("REMISES", 12), ("41,29", 38)],
                [("TOTAL", 0), ("REMISE", 6), ("IMMEDIATE", 13), ("11,90", 38)],
                [("TOTAL", 0), ("DES", 6), ("AVANTAGES", 10), ("11,90", 38)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("29,39", 38)],
            ]
        )
        assert summary_discount_ranks(lines) == {3}


class TestReferenceRanks:
    def test_section_totals_before_the_final_total_are_not_references(self):
        lines = priced(
            [
                [("PAIN", 0), ("0,99", 38)],
                [("TOTAL", 0), ("ALIMENTAIRE", 6), ("0,99", 38)],
                [("SAVON", 0), ("2,00", 38)],
                [("TOTAL", 0), ("HYGIENE", 6), ("2,00", 38)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("2,99", 38)],
                [("CB", 0), ("2,99", 38)],
            ]
        )
        assert reference_ranks(lines) == {4, 5}

    def test_subtotal_before_a_discount_and_ht_lines_are_never_references(self):
        lines = priced(
            [
                [("CAFE", 0), ("4,35", 38)],
                [("S/TOT", 0), ("18.47", 38)],
                [("SUB", 0), ("ORANGE", 4), ("-14.12", 37)],
                [("Total", 0), ("HT", 6), ("3.95", 38)],
                [("TOTAL", 0), ("4,35", 38)],
            ]
        )
        assert reference_ranks(lines) == {4}

    def test_without_any_total_line_every_rank_is_eligible(self):
        lines = priced(
            [
                [("CAFE", 0), ("4,35", 38)],
                [("4,35", 38)],
            ]
        )
        assert reference_ranks(lines) == {0, 1}


class TestConstraints:
    def test_final_total_line_is_an_evidence(self):
        lines = priced(
            [
                [("CLOU", 0), ("32,17", 38)],
                [("TO'AL", 0), ("Euro", 6), ("32.17", 38)],
            ]
        )
        result = constraints(lines)
        assert isinstance(result, Constraints)
        sources = {e.source: e for e in result.evidences}
        assert sources[TOTAL_LINE].cents == 3217
        assert sources[TOTAL_LINE].line_rank == 1

    def test_forced_ignore_merges_tax_and_summary_ranks(self):
        lines = priced(
            [
                [("CAFE", 0), ("4.50", 38)],
                [("REMISE", 0), ("-0.50", 37)],
                [("REMISE", 0), ("TOTALE", 7), ("-0.50", 37)],
                [("TOTAL", 0), ("4.00", 38)],
                [("TVA", 0), ("10%", 4), ("0.36", 38)],
                [("HT", 0), ("3.64", 38)],
            ]
        )
        result = constraints(lines)
        assert result.forced_ignore == frozenset({2, 4, 5})
        assert {e.source for e in result.evidences} == {TOTAL_LINE, TAX}


class TestSectionTotals:
    def test_bare_line_equal_to_the_running_sum_is_a_section_total(self):
        from reference.invariants import section_totals

        lines = priced(
            [
                [("POUDRE", 0), ("1.64", 38)],
                [("YAOURT", 0), ("1.30", 38)],
                [("RIZ", 0), ("1.60", 38)],
                [("ALINENTAIRE", 0), ("4.54", 38)],
                [("SAVON", 0), ("2.07", 38)],
                [("TOTAL", 0), ("BEAUTE", 6), ("2.07", 38)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("6.61", 38)],
            ]
        )
        assert section_totals(lines) == [3, 5]

    def test_single_item_before_a_bare_line_is_not_a_section(self):
        from reference.invariants import section_totals

        lines = priced(
            [
                [("CAFE", 0), ("2.00", 38)],
                [("2.00", 38)],
                [("TOTAL", 0), ("4.00", 38)],
            ]
        )
        assert section_totals(lines) == []

    def test_last_lexical_total_closes_a_one_item_section_after_another_section(self):
        from reference.invariants import section_totals

        lines = priced(
            [
                [("PURE", 0), ("7,05", 38)],
                [("KIT", 0), ("5,50", 38)],
                [("Total", 0), ("Soins", 6), ("12,55", 38)],
                [("KIT", 0), ("9.90", 38)],
                [("Total", 0), ("Non", 6), ("Alimentaire", 10), ("9.90", 38)],
                [("Cartes", 0), ("Bancaires", 7), ("22,45", 38)],
            ]
        )
        assert section_totals(lines) == [2, 4]

    def test_final_total_alone_is_not_a_section(self):
        from reference.invariants import section_totals

        lines = priced(
            [
                [("KIT", 0), ("9.90", 38)],
                [("Total", 0), ("Non", 6), ("Alimentaire", 10), ("9.90", 38)],
                [("Cartes", 0), ("Bancaires", 7), ("9.90", 38)],
            ]
        )
        assert section_totals(lines) == []

    def test_sections_sum_is_an_evidence_when_they_cover_every_item(self):
        from reference.invariants import SECTIONS

        lines = priced(
            [
                [("PURE", 0), ("7,05", 38)],
                [("KIT", 0), ("5,50", 38)],
                [("Total", 0), ("Soins", 6), ("12,55", 38)],
                [("CRF", 0), ("KIT", 4), ("9.90", 38)],
                [("Total", 0), ("Non", 6), ("Alimentaire", 10), ("9.90", 38)],
                [("Cartes", 0), ("Bancaires", 7), ("22,45", 38)],
            ]
        )
        result = constraints(lines)
        sections = [e for e in result.evidences if e.source == SECTIONS]
        assert [e.cents for e in sections] == [2245]
        assert sections[0].cutoff_rank == 4
        assert result.soft_ignore == frozenset({2, 4})

    def test_no_sections_evidence_when_items_follow_the_last_section(self):
        from reference.invariants import SECTIONS

        lines = priced(
            [
                [("PURE", 0), ("7,05", 38)],
                [("KIT", 0), ("5,50", 38)],
                [("Total", 0), ("Soins", 6), ("12,55", 38)],
                [("CRF", 0), ("KIT", 4), ("9.90", 38)],
                [("Total", 0), ("Non", 6), ("Alimentaire", 10), ("9.90", 38)],
                [("BONBON", 0), ("1.00", 38)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("23,45", 38)],
            ]
        )
        result = constraints(lines)
        assert not [e for e in result.evidences if e.source == SECTIONS]


class TestTaxRowsNeverItems:
    def test_item_priced_like_a_rate_is_not_a_tax_row(self):
        lines = priced(
            [
                [("KIT", 0), ("5,50", 38)],
                [("BOUGIE", 0), ("20,00", 38)],
                [("TOTAL", 0), ("25,50", 38)],
            ]
        )
        assert constraints(lines).forced_ignore == frozenset()

    def test_tax_lexicon_line_is_forced_ignore_even_without_a_partner(self):
        lines = priced(
            [
                [("BURGER", 0), ("8,95", 38)],
                [("TAX", 0), ("0,74", 38)],
                [("TOTAL", 0), ("9,69", 38)],
            ]
        )
        assert constraints(lines).forced_ignore == frozenset({1})

    def test_tax_inclusive_total_line_stays_a_reference(self):
        lines = priced(
            [
                [("CAFE", 0), ("2,00", 38)],
                [("TOTAL", 0), ("TVA", 6), ("INCL", 10), ("2,00", 38)],
            ]
        )
        result = constraints(lines)
        assert result.forced_ignore == frozenset()
        assert 1 in result.reference_ranks


class TestSubtotalReference:
    def test_subtotal_followed_by_a_discount_is_not_a_reference(self):
        lines = priced(
            [
                [("LIT", 0), ("55,00", 38)],
                [("SOUS", 0), ("TOTAL", 5), ("55,00", 38)],
                [("REMISE", 0), ("-5,10", 37)],
                [("TOTAL", 0), ("49,90", 38)],
            ]
        )
        assert reference_ranks(lines) == {3}

    def test_subtotal_without_following_discount_is_a_reference(self):
        lines = priced(
            [
                [("BURGER", 0), ("8,95", 38)],
                [("SUBTOTAL", 0), ("8,95", 38)],
                [("TAX", 0), ("0,74", 38)],
                [("TOTAL", 0), ("9,69", 38)],
            ]
        )
        assert reference_ranks(lines) == {1, 3}


class TestFinalTotalBeforePayment:
    def test_total_printed_after_the_payment_is_not_the_final_total(self):
        from reference.invariants import _last_total_rank

        lines = priced(
            [
                [("LAIT", 0), ("2,00", 38)],
                [("Total", 0), ("19", 6), ("articles", 9), ("2,00", 38)],
                [("CB", 0), ("2,00", 38)],
                [("Total", 0), ("Bon", 6), ("immediat", 10), ("3,72", 38)],
            ]
        )
        assert _last_total_rank(lines) == 1
        assert 1 in reference_ranks(lines)

    def test_intermediate_total_followed_only_by_taxes_is_eligible(self):
        lines = priced(
            [
                [("TACO", 0), ("4,95", 38)],
                [("Net", 0), ("Total", 4), ("4,95", 38)],
                [("Sales", 0), ("Tax", 6), ("0,52", 38)],
                [("TOTAL", 0), ("5,47", 38)],
            ]
        )
        assert reference_ranks(lines) == {1, 3}

    def test_section_total_followed_by_items_stays_ineligible(self):
        lines = priced(
            [
                [("PAIN", 0), ("0,99", 38)],
                [("TOTAL", 0), ("ALIMENTAIRE", 6), ("0,99", 38)],
                [("SAVON", 0), ("2,00", 38)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("2,99", 38)],
            ]
        )
        assert reference_ranks(lines) == {3}

    def test_total_before_discounts_stays_ineligible(self):
        lines = priced(
            [
                [("OREILLER", 0), ("11,90", 38)],
                [("TOTAL", 0), ("AVANT", 6), ("REMISES", 12), ("11,90", 38)],
                [("TOTAL", 0), ("REMISE", 6), ("IMMEDIATE", 13), ("-11,90", 37)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("0,00", 38)],
            ]
        )
        assert 1 not in reference_ranks(lines)

    def test_recap_line_of_the_same_amount_does_not_block_the_subtotal(self):
        lines = priced(
            [
                [("ICED", 0), ("TEA", 5), ("4.50", 38)],
                [("BRANZINO", 0), ("40.00", 38)],
                [("FOOD", 0), ("44.50", 38)],
                [("SUB-TOTAL", 0), ("44.50", 38)],
                [("TAX", 0), ("3.95", 38)],
                [("TOTAL", 0), ("48.45", 38)],
            ]
        )
        assert 3 in reference_ranks(lines)


class TestPositiveDiscountRecap:
    def test_positive_recap_of_the_discounts_is_not_the_final_total(self):
        lines = priced(
            [
                [("LITIERE", 0), ("16,99", 37)],
                [("Reduction", 0), ("-4,49", 37)],
                [("MAISON", 0), ("399,00", 37)],
                [("Reduction", 0), ("-50,00", 37)],
                [("TOTAL", 0), ("[2]", 6), ("EUR", 10), ("361,50", 37)],
                [("Total", 0), ("remise:", 6), ("EUR", 14), ("54,49", 38)],
            ]
        )
        structure = constraints(lines)
        assert _last_total_rank(lines) == 4
        assert structure.reference_ranks == {4}
        assert 5 in structure.forced_ignore

    def test_a_single_discount_above_never_makes_a_recap(self):
        lines = priced(
            [
                [("LITIERE", 0), ("16,99", 37)],
                [("Reduction", 0), ("-4,49", 37)],
                [("TOTAL", 0), ("12,50", 37)],
                [("PORT", 0), ("4,49", 38)],
            ]
        )
        assert 3 not in constraints(lines).forced_ignore

    def test_section_totals_are_not_mistaken_for_recaps(self):
        lines = priced(
            [
                [("THON", 0), ("0,89", 38)],
                [("REMISE", 0), ("-0,56", 37)],
                [("TOTAL", 0), ("ALIMENTAIRE", 6), ("0,33", 38)],
                [("SAVON", 0), ("3,99", 38)],
                [("TOTAL", 0), ("A", 6), ("PAYER", 8), ("4,32", 38)],
            ]
        )
        assert _last_total_rank(lines) == 4
        assert 2 not in constraints(lines).forced_ignore


class TestSelfEvidentTaxRow:
    def test_a_row_carrying_its_own_ht_tax_ttc_triple_is_a_tax_row(self):
        lines = priced(
            [
                [("LITIERE", 0), ("374,00", 37)],
                [("TOTAL", 0), ("EUR", 6), ("374,00", 37)],
                [("D", 0), ("20,", 2), ("62,33", 20), ("374,00", 29), ("311,67", 38)],
                [("tot", 0), ("Vat", 4), ("62,33", 20), ("374,00", 29), ("311,67", 38)],
            ]
        )
        structure = constraints(lines)
        assert _last_total_rank(lines) == 1
        assert {2, 3} <= structure.forced_ignore

    def test_three_unrelated_amounts_stay_an_ordinary_line(self):
        lines = priced(
            [
                [("PACK", 0), ("3,00", 20), ("4,00", 29), ("9,00", 38)],
                [("TOTAL", 0), ("9,00", 38)],
            ]
        )
        assert 0 not in constraints(lines).forced_ignore
