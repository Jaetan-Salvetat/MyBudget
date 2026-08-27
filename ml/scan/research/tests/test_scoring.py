from bench.scoring import count_edits


class TestCountEdits:
    def test_exact_match(self):
        assert count_edits([(2.0, 0.0), (3.0, 0.0)], [2.0, 3.0]) == 0

    def test_missed_item(self):
        assert count_edits([(2.0, 0.0)], [2.0, 3.0]) == 1

    def test_wrong_item(self):
        assert count_edits([(2.0, 0.0), (9.0, 0.0)], [2.0, 3.0]) == 2

    def test_missed_zero_amount_is_free(self):
        """Un article attendu à 0,00 € manqué n'a aucun impact monétaire :
        composants de menu fast-food, lignes gratuites."""
        assert count_edits([(8.9, 0.0)], [8.9, 0.0, 0.0]) == 0

    def test_extra_zero_amount_still_counts(self):
        assert count_edits([(8.9, 0.0), (0.0, 0.0)], [8.9]) == 1

    def test_negative_expected_matches_discount(self):
        """Convention golden « article négatif » (subvention, annulation)
        équivalente à la convention pipeline « remise sur l'article
        précédent » : même somme nette, zéro correction."""
        assert count_edits([(2.31, 1.22), (0.31, 0.0)], [2.31, 0.31, -1.22]) == 0

    def test_negative_expected_without_matching_discount(self):
        assert count_edits([(2.31, 0.0), (0.31, 0.0)], [2.31, 0.31, -1.22]) == 1


class TestParseExcluded:
    def test_name_with_reason(self):
        from bench.device_flow import parse_excluded

        text = "t1test_68  ocr_montants_absents\nt1train_405 golden_non_checksummable"
        assert parse_excluded(text) == {"t1test_68", "t1train_405"}

    def test_skips_comments_and_blank_lines(self):
        from bench.device_flow import parse_excluded

        text = "# corpus sain\n\nt1test_1  x\n"
        assert parse_excluded(text) == {"t1test_1"}

    def test_empty_text(self):
        from bench.device_flow import parse_excluded

        assert parse_excluded("") == set()
