"""La lecture du prix : ce que le modèle autorise, ce que le décodeur tranche.

La regex stricte décidait seule quelles lignes pouvaient être des articles, et
elle en écartait 93 sur les 100 que le corpus d'évaluation perdait. La laxité
est maintenant gouvernée par le rôle prédit, et une ligne propose tous ses
montants plausibles au lieu d'un seul.
"""

from __future__ import annotations

import numpy as np
from test_structure import line, receipt_lines

from annotate.schema import DATE_LINE, DISCOUNT, ITEM, NOISE, STORE, TOTAL
from reference.decode_roles import lax_ranks
from reference.line_features import priced_lines
from reference.line_labels import TAGGER_ROLES
from reference.structure import price_candidates
from reference.structure_roles import extract_roles


def amounts(text: str, lax: bool) -> list[float]:
    tokens = [(token, index * 6) for index, token in enumerate(text.split())]
    return [round(price, 2) for price, _ in price_candidates(line(0, *tokens), lax)]


class TestStrictReadingIsUnchanged:
    def test_a_clean_price_is_read_without_laxity(self):
        assert amounts("PAIN 1,20", lax=False) == [1.20]

    def test_a_glued_currency_escapes_the_strict_reading(self):
        assert amounts("CARRE FOURRE T1 2.15Eur", lax=False) == []

    def test_a_line_the_strict_reader_reaches_is_never_widened(self):
        # Rouvrir une ligne déjà lisible donnerait au décodeur de quoi
        # retomber sur la bonne somme avec des montants faux : mesuré sur
        # t1train_214, quatre prix unitaires pris pour des prix ligne.
        assert amounts("PAIN 1,20 2,40Eur", lax=True) == [1.20]


class TestLaxReading:
    def test_currency_glued_to_the_price(self):
        assert amounts("CARRE FOURRE T1 2.15Eur", lax=True) == [2.15]

    def test_tax_class_in_parentheses(self):
        assert amounts("0.858kg x 2.69Eur/kg 2.31(2)", lax=True) == [2.31, 2.69]

    def test_trailing_junk_digit(self):
        assert amounts("SHEBA SOUPE 160G 2.342", lax=True) == [2.34]

    def test_a_computed_line_offers_both_its_amounts(self):
        assert amounts("OIGNON 2 x 0.85EUR = 1.70EUR", lax=True) == [1.70, 0.85]

    def test_a_line_without_any_amount_offers_nothing(self):
        assert amounts("MERCI DE VOTRE VISITE", lax=True) == []

    def test_a_percentage_is_never_an_amount(self):
        assert amounts("(Remise de -14.29%)", lax=True) == []
        assert amounts("Remise -15.65% 2.10", lax=True) == [2.10]

    def test_the_same_amount_read_twice_is_one_candidate(self):
        assert amounts("PAIN 1.20Eur 1.20Eur", lax=True) == [1.20]


class TestLaxRanksFollowTheTagger:
    def _probabilities(self, roles: list[str]) -> np.ndarray:
        rows = np.zeros((len(roles), len(TAGGER_ROLES)))
        for index, role in enumerate(roles):
            rows[index, TAGGER_ROLES.index(role)] = 1.0
        return rows

    def test_amount_bearing_roles_are_lax(self):
        roles = [ITEM, DISCOUNT, TOTAL]
        assert lax_ranks(self._probabilities(roles)) == {0, 1, 2}

    def test_roles_that_carry_no_amount_stay_strict(self):
        roles = [STORE, DATE_LINE, NOISE]
        assert lax_ranks(self._probabilities(roles)) == frozenset()

    def test_only_the_designated_lines_widen(self):
        roles = [STORE, ITEM, NOISE]
        assert lax_ranks(self._probabilities(roles)) == {1}


class TestPricedLines:
    def _rows(self):
        return receipt_lines(
            [
                [("CARREFOUR", 0)],
                [("CARRE", 0), ("FOURRE", 6), ("2.15Eur", 20)],
                [("TOTAL", 0), ("2,15", 20)],
            ]
        )

    def test_a_line_the_tagger_ignores_keeps_the_strict_reading(self):
        assert [p.index for p in priced_lines(self._rows())] == [2]

    def test_a_designated_line_enters_with_its_lax_reading(self):
        priced = priced_lines(self._rows(), lax_ranks=frozenset({1}))
        assert [p.index for p in priced] == [1, 2]
        assert priced[0].price == 2.15

    def test_every_candidate_travels_with_the_line(self):
        rows = receipt_lines(
            [
                [
                    ("OIGNON", 0),
                    ("2", 8),
                    ("x", 10),
                    ("0.85EUR", 12),
                    ("=", 20),
                    ("1.70EUR", 22),
                ]
            ]
        )
        priced = priced_lines(rows, lax_ranks=frozenset({0}))
        assert priced[0].candidates == [1.70, 0.85]


class TestExtractRoles:
    def test_an_item_whose_price_escapes_the_regex_is_kept(self):
        rows = receipt_lines(
            [
                [("CARRE", 0), ("FOURRE", 6), ("2.15Eur", 20)],
                [("TOTAL", 0), ("2,15", 20)],
            ]
        )
        receipt = extract_roles(rows, [ITEM, TOTAL])
        assert [item.amount for item in receipt.items] == [2.15]

    def test_a_line_the_tagger_calls_noise_is_not_read_lax(self):
        rows = receipt_lines(
            [
                [("PAIN", 0), ("2,15", 20)],
                [("SIRET", 0), ("1.23Eur", 20)],
            ]
        )
        receipt = extract_roles(rows, [ITEM, NOISE])
        assert [item.amount for item in receipt.items] == [2.15]
