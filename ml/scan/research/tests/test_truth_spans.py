"""Vérité de span : quels mots d'une ligne composent le libellé."""

from __future__ import annotations

from reference.lines import PhysicalLine, Word
from truth.spans import align, spans_from_golden


def line(*tokens: str) -> PhysicalLine:
    words = []
    left = 0.0
    for token in tokens:
        width = 10.0 * len(token)
        words.append(
            Word(
                text=token,
                left=left,
                top=0.0,
                right=left + width,
                bottom=20.0,
                confidence=1.0,
            )
        )
        left += width + 10.0
    return PhysicalLine(words=words)


class TestAlign:
    def test_le_libelle_occupe_toute_la_ligne(self) -> None:
        assert align(line("PAIN", "COMPLET", "BIO"), "PAIN COMPLET BIO") == (0, 3)

    def test_un_code_a_gauche_reste_hors_du_libelle(self) -> None:
        assert align(
            line("583877", "DIAMOND", "TAPIS"), "DIAMOND TAPIS"
        ) == (1, 3)

    def test_un_prix_et_une_quantite_a_droite_restent_hors_du_libelle(self) -> None:
        assert align(
            line("CVDC", "CARTE", "VITRIN", "4.40", "1"), "CVDC CARTE VITRIN"
        ) == (0, 3)

    def test_la_casse_et_les_accents_ne_comptent_pas(self) -> None:
        assert align(line("Café", "Grand", "Arôme"), "CAFE GRAND AROME") == (0, 3)

    def test_la_ponctuation_du_golden_ne_compte_pas(self) -> None:
        assert align(line("C.POIRE,CHOC", "5.40"), "C. POIRE, CHOC") == (0, 1)

    def test_un_libelle_absent_de_la_ligne_ne_s_aligne_pas(self) -> None:
        assert align(line("Net", "0.335kg*4.35€/kg"), "EPINARD VRAC") is None

    def test_un_degat_ocr_disqualifie_la_ligne(self) -> None:
        """La vérité doit être sûre : une ligne à moitié lue n'enseigne rien."""
        assert align(line("DIAMONO", "TAPI5"), "DIAMOND TAPIS") is None

    def test_le_plus_court_intervalle_l_emporte(self) -> None:
        """« AIL » deux fois sur la ligne : le libellé est le premier mot,
        pas l'intervalle qui les englobe."""
        assert align(line("AIL", "AIL", "2.30"), "AIL") == (0, 1)

    def test_une_ligne_vide_ne_s_aligne_pas(self) -> None:
        assert align(PhysicalLine(words=[]), "PAIN") is None

    def test_un_libelle_vide_ne_s_aligne_pas(self) -> None:
        assert align(line("PAIN"), "  ") is None


class TestSpansFromGolden:
    def test_chaque_libelle_trouve_sa_ligne(self) -> None:
        lines = [
            line("CARREFOUR", "CITY"),
            line("PAIN", "COMPLET", "2,50"),
            line("1", "BRIOCHE", "1,20"),
        ]
        items = [{"name": "PAIN COMPLET"}, {"name": "BRIOCHE"}]
        assert spans_from_golden(lines, items) == [(1, 0, 2), (2, 1, 2)]

    def test_un_libelle_lisible_sur_deux_lignes_est_ecarte(self) -> None:
        """Rien ne dit laquelle des deux nomme l'article."""
        lines = [line("PAIN", "2,50"), line("PAIN", "OFFERT")]
        assert spans_from_golden(lines, [{"name": "PAIN"}]) == []

    def test_un_article_achete_deux_fois_garde_ses_deux_lignes(self) -> None:
        lines = [line("PAIN", "2,50"), line("PAIN", "2,50")]
        items = [{"name": "PAIN"}, {"name": "PAIN"}]
        assert spans_from_golden(lines, items) == [(0, 0, 1), (1, 0, 1)]

    def test_un_libelle_introuvable_ne_donne_rien(self) -> None:
        assert spans_from_golden([line("PAIN", "2,50")], [{"name": "BRIOCHE"}]) == []
