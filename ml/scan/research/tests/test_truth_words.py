"""Vérité au niveau du mot : quels mots écrivent le nom, lequel porte le
montant — sans qu'aucune ligne n'ait été décidée."""

from __future__ import annotations

from reference.lines import Word
from truth.words import amount_word, item_truth, name_words

CHAR_WIDTH = 10.0
GLYPH_HEIGHT = 20.0
ROW_PITCH = 25.0


def word(text: str, column: float, row: float) -> Word:
    left = column * CHAR_WIDTH
    top = row * ROW_PITCH
    return Word(
        text=text,
        left=left,
        top=top,
        right=left + len(text) * CHAR_WIDTH,
        bottom=top + GLYPH_HEIGHT,
        confidence=1.0,
    )


# Un ticket ordinaire : trois rangées, code à gauche, prix à droite.
PLAIN = [
    word("6015", 0, 0),
    word("SANDWICH", 8, 0),
    word("POULET", 18, 0),
    word("2,95", 40, 0),
    word("6011", 0, 1),
    word("SALADE", 8, 1),
    word("1,29", 40, 1),
]


class TestNameWords:
    def test_le_nom_est_rendu_comme_les_mots_qui_l_ecrivent(self) -> None:
        assert name_words(PLAIN, "SANDWICH POULET") == (1, 2)

    def test_un_code_a_gauche_et_un_prix_a_droite_restent_dehors(self) -> None:
        assert name_words(PLAIN, "SALADE") == (5,)

    def test_la_casse_et_les_accents_ne_comptent_pas(self) -> None:
        words = [word("Café", 0, 0), word("Arôme", 6, 0)]
        assert name_words(words, "CAFE AROME") == (0, 1)

    def test_un_nom_que_l_ocr_a_detruit_est_rejete(self) -> None:
        """La vérité élimine, elle ne répare pas : une lecture à moitié fausse
        n'enseignerait qu'une frontière inventée."""
        words = [word("DIAMONO", 0, 0), word("TAPI5", 9, 0)]
        assert name_words(words, "DIAMOND TAPIS") is None

    def test_un_nom_absent_du_ticket_est_rejete(self) -> None:
        assert name_words(PLAIN, "EPINARD VRAC") is None

    def test_deux_rangees_entrelacees_ne_cachent_pas_le_nom(self) -> None:
        """Le défaut que `cluster_lines` fabrique : les mots de deux rangées
        se retrouvent mêlés dans l'ordre de lecture. La recherche est
        spatiale, donc l'entrelacement ne la gêne pas."""
        interleaved = [
            word("COMTE", 0, 0),
            word("1", 30, 1),
            word("6", 6, 0),
            word("x", 33, 1),
            word("MOIS", 8, 0),
            word("3,35", 40, 1),
            word("250G", 14, 0),
        ]
        assert name_words(interleaved, "COMTE 6 MOIS 250G") == (0, 2, 4, 6)

    def test_le_nom_ne_traverse_pas_deux_rangees(self) -> None:
        """Deux rangées différentes ne composent pas un nom, même si leurs
        mots l'écrivent : ce serait inventer un article."""
        split = [word("PAIN", 0, 0), word("COMPLET", 0, 4)]
        assert name_words(split, "PAIN COMPLET") is None

    def test_le_plus_court_ensemble_l_emporte(self) -> None:
        """« AIL » deux fois : le nom est un mot, pas l'intervalle qui les
        englobe."""
        words = [word("AIL", 0, 0), word("AIL", 5, 0), word("2,30", 40, 0)]
        assert name_words(words, "AIL") == (0,)


class TestAmountWord:
    def test_le_montant_est_le_mot_qui_le_porte(self) -> None:
        assert amount_word(PLAIN, 2.95) == 3

    def test_un_montant_colle_a_sa_devise_reste_lisible(self) -> None:
        """La lecture ne connaît qu'une règle — le motif décimal du mot. Ce
        qui l'entoure ne la concerne pas : c'est au modèle de désigner le
        mot, pas à une regex de reconnaître chaque graphie d'enseigne."""
        words = [word("PAIN", 0, 0), word("2.95EUR", 40, 0)]
        assert amount_word(words, 2.95) == 1

    def test_un_montant_absent_du_ticket_n_a_pas_de_mot(self) -> None:
        assert amount_word(PLAIN, 9.99) is None

    def test_le_montant_negatif_se_lit_en_valeur_absolue(self) -> None:
        """Une remise est annotée en valeur absolue ; le ticket l'imprime
        signée."""
        words = [word("REMISE", 0, 0), word("-1,50", 40, 0)]
        assert amount_word(words, 1.50) == 1

    def test_deux_mots_au_meme_montant_laissent_la_question_sans_reponse(
        self,
    ) -> None:
        words = [word("2,95", 20, 0), word("2,95", 40, 0)]
        assert amount_word(words, 2.95) is None

    def test_restreindre_les_candidats_leve_l_ambiguite(self) -> None:
        """Le prix unitaire d'une rangée et le montant d'une autre portent le
        même nombre : c'est la rangée qui tranche, pas un ordre choisi."""
        words = [word("2,95", 20, 0), word("2,95", 40, 4)]
        assert amount_word(words, 2.95, within=(1,)) == 1


class TestItemTruth:
    def test_l_article_rend_ses_mots_et_son_montant(self) -> None:
        truth = item_truth(PLAIN, "SANDWICH POULET", 2.95)
        assert truth is not None
        assert truth.name_words == (1, 2)
        assert truth.amount_word == 3

    def test_le_montant_est_cherche_sur_la_rangee_du_nom(self) -> None:
        """« 1 x 1,29 » ailleurs sur le ticket porte le même nombre que le
        montant de l'article ; la rangée du nom désigne lequel compte."""
        words = [
            word("SALADE", 8, 0),
            word("1,29", 40, 0),
            word("1", 8, 6),
            word("x", 11, 6),
            word("1,29", 20, 6),
        ]
        truth = item_truth(words, "SALADE", 1.29)
        assert truth is not None
        assert truth.amount_word == 1

    def test_un_nom_introuvable_ne_fait_pas_d_article(self) -> None:
        assert item_truth(PLAIN, "EPINARD VRAC", 2.95) is None

    def test_un_montant_introuvable_laisse_l_article_sans_mot_porteur(
        self,
    ) -> None:
        """Le nom est sûr, le montant ne l'est pas : la vérité garde ce
        qu'elle sait et n'invente pas le reste."""
        truth = item_truth(PLAIN, "SANDWICH POULET", 9.99)
        assert truth is not None
        assert truth.name_words == (1, 2)
        assert truth.amount_word is None
