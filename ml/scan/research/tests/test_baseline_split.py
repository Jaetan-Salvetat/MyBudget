"""Un groupe de mots qui recouvre deux lignes imprimées doit se rescinder.

Le regroupement compare chaque mot à l'enveloppe verticale du groupe, et cette
enveloppe grandit en absorbant des mots inclinés : sur un ticket courbé elle
finit par atteindre la ligne d'à côté. Les deux lignes imprimées n'en font plus
qu'une, et la seconde y perd son montant — personne ne le lit jamais.
"""

from __future__ import annotations

import math

from reference.lines import Word, cluster_lines, split_baselines

HEIGHT = 30.0
CHAR = 14.0


def word(text: str, column: int, center_y: float) -> Word:
    left = column * CHAR
    return Word(
        text=text,
        left=left,
        top=center_y - HEIGHT / 2,
        right=left + len(text) * CHAR,
        bottom=center_y + HEIGHT / 2,
        confidence=0.9,
    )


def printed_line(tokens: list[tuple[str, int]], baseline: float, slope: float):
    """Une ligne imprimée, inclinée : chaque mot suit la pente à son abscisse."""
    return [
        word(text, column, baseline + slope * column * CHAR) for text, column in tokens
    ]


def texts(groups) -> list[list[str]]:
    return [[w.text for w in sorted(group, key=lambda w: w.left)] for group in groups]


class TestSingleLineIsNeverSplit:
    def test_two_words_stay_together_whatever_their_offset(self):
        # La droite ajustée passe exactement par deux points : aucun résidu,
        # donc aucune séparation possible. C'est la garantie que le cas le plus
        # courant — un libellé et son prix — ne se coupe jamais en deux.
        pair = [word("PAIN", 0, 0.0), word("2,50", 38, 200.0)]
        assert len(split_baselines(pair)) == 1

    def test_a_flat_line_is_one_group(self):
        line = printed_line([("PAIN", 0), ("BIO", 6), ("2,50", 38)], 100.0, 0.0)
        assert len(split_baselines(line)) == 1

    def test_a_steeply_tilted_line_is_still_one_group(self):
        # 6°, bien au-delà de ce qu'une photo tenue à la main produit : la
        # pente est absorbée par l'ajustement, pas par un seuil.
        slope = math.tan(math.radians(6))
        line = printed_line([("PAIN", 0), ("BIO", 6), ("2,50", 38)], 100.0, slope)
        assert len(split_baselines(line)) == 1


class TestTwoPrintedLinesAreSeparated:
    def _merged(self, slope: float = 0.0):
        """Les deux lignes du bloc litière, telles que le regroupement les
        colle : le libellé et son prix, la remise et le sien."""
        return printed_line(
            [("PREM", 0), ("AGGLO", 6), ("16,99", 38)], 100.0, slope
        ) + printed_line([("Reduction", 0), ("-4,49", 38)], 140.0, slope)

    def test_a_merged_pair_splits_back_in_two(self):
        groups = split_baselines(self._merged())
        assert len(groups) == 2
        assert texts(groups) == [
            ["PREM", "AGGLO", "16,99"],
            ["Reduction", "-4,49"],
        ]

    def test_the_split_survives_a_shared_tilt(self):
        slope = math.tan(math.radians(4))
        groups = split_baselines(self._merged(slope))
        assert texts(groups) == [
            ["PREM", "AGGLO", "16,99"],
            ["Reduction", "-4,49"],
        ]

    def test_no_word_is_lost_nor_duplicated(self):
        merged = self._merged()
        regrouped = [w for group in split_baselines(merged) for w in group]
        assert sorted(w.text for w in regrouped) == sorted(w.text for w in merged)

    def test_each_line_keeps_its_own_amount(self):
        groups = split_baselines(self._merged())
        amounts = [[w.text for w in group if "," in w.text] for group in groups]
        assert amounts == [["16,99"], ["-4,49"]]


class TestClusteringUsesTheSplit:
    def test_a_curved_receipt_yields_one_line_per_printed_line(self):
        # Le cas Maxizoo réduit à l'os : l'inclinaison résiduelle fait dériver
        # la bande d'une ligne jusqu'à absorber toute la suivante.
        words = printed_line(
            [("PREM", 0), ("AGGLO", 6), ("16,99", 38)], 100.0, 0.03
        ) + printed_line([("Reduction", 0), ("-4,49", 38)], 125.0, 0.03)
        assert len(cluster_lines(words, split=False)) == 1
        lines = cluster_lines(words)
        assert [line.text for line in lines] == [
            "PREM AGGLO 16,99",
            "Reduction -4,49",
        ]

    def test_two_well_separated_lines_are_untouched(self):
        words = printed_line([("PAIN", 0), ("2,50", 38)], 100.0, 0.0) + printed_line(
            [("LAIT", 0), ("3,00", 38)], 300.0, 0.0
        )
        assert [line.text for line in cluster_lines(words)] == [
            "PAIN 2,50",
            "LAIT 3,00",
        ]
