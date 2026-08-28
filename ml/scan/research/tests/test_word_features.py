"""Features par mot : ce qui sépare un libellé d'une colonne voisine."""

from __future__ import annotations

from reference.lines import PhysicalLine, Word
from reference.word_features import FEATURE_NAMES, NEIGHBOUR_ABSENT, featurize

CHAR_WIDTH = 10.0
LINE_HEIGHT = 20.0


def word(text: str, column: float, row: int) -> Word:
    left = column * CHAR_WIDTH
    top = row * (LINE_HEIGHT + 5)
    return Word(
        text=text,
        left=left,
        top=top,
        right=left + len(text) * CHAR_WIDTH,
        bottom=top + LINE_HEIGHT,
        confidence=1.0,
    )


def line(row: int, *tokens: tuple[str, float]) -> PhysicalLine:
    return PhysicalLine(words=[word(text, column, row) for text, column in tokens])


def column_of(name: str) -> int:
    return FEATURE_NAMES.index(name)


# Un ticket à trois colonnes : code, libellé, prix.
TICKET = [
    line(0, ("6015", 0), ("SANDWICH POULET", 8), ("2,95", 40)),
    line(1, ("6011", 0), ("SALADE CESAR", 8), ("1,29", 40)),
    line(2, ("6012", 0), ("EAU MINERALE", 8), ("0,71", 40)),
]


class TestBandes:
    def test_une_colonne_de_codes_est_vue_comme_numerique(self) -> None:
        rows = featurize(TICKET)
        assert rows[0][0][column_of("band_digit_ratio")] == 1.0

    def test_une_colonne_de_libelles_est_vue_comme_alphabetique(self) -> None:
        rows = featurize(TICKET)
        assert rows[0][1][column_of("band_alpha_ratio")] > 0.8

    def test_une_colonne_de_prix_est_vue_comme_telle(self) -> None:
        rows = featurize(TICKET)
        assert rows[0][2][column_of("band_price_ratio")] == 1.0

    def test_un_mot_seul_dans_sa_bande_n_a_pas_de_colonne(self) -> None:
        """La bande n'est remplie par personne : le modèle doit le savoir."""
        rows = featurize([*TICKET, line(3, ("MERCI DE VOTRE VISITE", 60))])
        assert rows[3][0][column_of("band_fill")] == 0.0


class TestGeometrie:
    def test_le_premier_et_le_dernier_mot_sont_marques(self) -> None:
        rows = featurize(TICKET)
        assert rows[0][0][column_of("is_first")] == 1.0
        assert rows[0][2][column_of("is_last")] == 1.0

    def test_l_ecart_avant_le_premier_mot_est_absent(self) -> None:
        rows = featurize(TICKET)
        assert rows[0][0][column_of("gap_before")] == NEIGHBOUR_ABSENT

    def test_l_ecart_separe_deux_colonnes(self) -> None:
        rows = featurize(TICKET)
        assert rows[0][1][column_of("gap_after")] > 0.0


class TestPrix:
    def test_le_mot_qui_porte_le_prix_est_designe(self) -> None:
        rows = featurize(TICKET)
        assert rows[0][2][column_of("is_price_word")] == 1.0
        assert rows[0][1][column_of("is_price_word")] == 0.0

    def test_un_prix_fragmente_reste_reconnu(self) -> None:
        """L'OCR coupe « 2,95 » au séparateur : la colonne du prix ne bouge
        pas, et les deux morceaux en font partie."""
        rows = featurize([line(0, ("PAIN", 0), ("2,", 40), ("95", 42.5))])
        assert rows[0][0][column_of("is_price_word")] == 0.0
        assert rows[0][1][column_of("is_price_word")] == 1.0
        assert rows[0][2][column_of("is_price_word")] == 1.0

    def test_une_ligne_sans_prix_n_a_pas_de_distance_au_prix(self) -> None:
        rows = featurize([line(0, ("BOULANGERIE", 0), ("DUPONT", 12))])
        assert rows[0][0][column_of("dist_to_price")] == NEIGHBOUR_ABSENT


class TestContrat:
    def test_chaque_mot_donne_un_vecteur_de_la_bonne_largeur(self) -> None:
        rows = featurize(TICKET)
        assert [len(row) for row in rows] == [3, 3, 3]
        assert all(len(vector) == len(FEATURE_NAMES) for row in rows for vector in row)

    def test_un_ticket_vide_ne_donne_rien(self) -> None:
        assert featurize([]) == []
