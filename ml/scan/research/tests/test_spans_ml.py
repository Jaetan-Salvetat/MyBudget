"""Le libellé est l'intervalle de mots que le modèle juge le plus probable."""

from __future__ import annotations

from reference.spans_ml import best_span, span_text


class TestBestSpan:
    def test_l_intervalle_retenu_est_celui_des_mots_probables(self) -> None:
        words = ["583877", "DIAMOND", "TAPIS", "29.95"]
        assert best_span(words, [0.1, 0.9, 0.9, 0.02]) == (1, 3)

    def test_l_intervalle_reste_contigu(self) -> None:
        """Un libellé ne se coupe pas en deux autour d'un code : le mot isolé
        ne peut pas rejoindre le nom sans emmener ce qui les sépare."""
        assert best_span(["PAIN", "6015", "COMPLET"], [0.9, 0.05, 0.6]) == (0, 1)

    def test_le_pont_se_paie_quand_il_vaut_le_coup(self) -> None:
        assert best_span(["PAIN", "6015", "COMPLET"], [0.99, 0.45, 0.99]) == (0, 3)

    def test_un_libelle_sans_lettre_n_en_est_pas_un(self) -> None:
        """Le modèle ne peut pas nommer un article avec une pesée : la
        recherche ne considère que les intervalles qui portent des lettres."""
        assert best_span(["0.335", "4.35"], [0.9, 0.9]) is None

    def test_l_intervalle_le_plus_probable_porte_des_lettres(self) -> None:
        assert best_span(["2", "AVOCAT"], [0.9, 0.55]) == (0, 2)

    def test_une_ligne_vide_ne_donne_pas_d_intervalle(self) -> None:
        assert best_span([], []) is None


class TestSpanText:
    def test_le_texte_est_celui_des_mots_de_l_intervalle(self) -> None:
        assert span_text(["583877", "DIAMOND", "TAPIS"], (1, 3)) == "DIAMOND TAPIS"
