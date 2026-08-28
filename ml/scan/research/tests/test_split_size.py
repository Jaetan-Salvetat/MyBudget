"""Le conditionnement sorti du nom, et ce qui interdit de l'inventer."""

from __future__ import annotations

from annotate.split_size import (
    Split,
    accepted,
    applied,
    golden_item,
    inconsistencies,
)

ORIGINAL = "*230G WASA FIBRES"


class TestAccepted:
    def test_le_calibre_en_tete_sort_du_nom(self) -> None:
        assert accepted(ORIGINAL, Split("WASA FIBRES", "230G"))

    def test_le_calibre_en_queue_sort_du_nom(self) -> None:
        assert accepted("BAGUETTE 250G", Split("BAGUETTE", "250G"))

    def test_un_nom_sans_calibre_reste_entier(self) -> None:
        assert accepted("PAIN COMPLET", Split("PAIN COMPLET", None))

    def test_le_calibre_interieur_reste_dans_le_nom(self) -> None:
        """La vérité de span est un intervalle contigu : le retirer rendrait
        le nom introuvable sur sa ligne. Il est relevé, pas retiré."""
        assert accepted("BEURRE 250G DOUX", Split("BEURRE 250G DOUX", "250G"))

    def test_un_mot_invente_est_refuse(self) -> None:
        assert not accepted(ORIGINAL, Split("WASA FIBRES BIO", "230G"))

    def test_un_nom_non_contigu_est_refuse(self) -> None:
        """Sans contiguïté, `truth/spans.py` ne peut plus aligner le nom."""
        assert not accepted("BEURRE 250G DOUX", Split("BEURRE DOUX", "250G"))

    def test_un_calibre_absent_du_nom_est_refuse(self) -> None:
        assert not accepted(ORIGINAL, Split("WASA FIBRES", "500G"))

    def test_une_orthographe_corrigee_est_refusee(self) -> None:
        """L'OCR abîme, l'annotation recopie. Corriger rend l'alignement
        introuvable, donc la vérité inutilisable."""
        assert not accepted("*230G WASA FIBRE", Split("WASA FIBRES", "230G"))

    def test_un_nom_vide_est_refuse(self) -> None:
        assert not accepted(ORIGINAL, Split("", "230G"))

    def test_un_nom_sans_lettre_est_refuse(self) -> None:
        assert not accepted("*230G 500", Split("500", "230G"))

    def test_la_casse_du_nom_ne_doit_pas_changer(self) -> None:
        assert not accepted("Pain Complet", Split("PAIN COMPLET", None))


class TestApplied:
    def test_le_nom_et_le_conditionnement_remplacent_l_entree(self) -> None:
        entry = {"role": "item", "amount": 1.89, "name": ORIGINAL}
        assert applied(entry, {ORIGINAL: Split("WASA FIBRES", "230G")}) == {
            "role": "item",
            "amount": 1.89,
            "name": "WASA FIBRES",
            "size": "230G",
        }

    def test_un_nom_sans_conditionnement_ne_gagne_pas_le_champ(self) -> None:
        entry = {"role": "item", "amount": 1.0, "name": "PAIN"}
        assert applied(entry, {"PAIN": Split("PAIN", None)}) == entry

    def test_un_nom_absent_de_la_table_reste_intact(self) -> None:
        entry = {"role": "item", "amount": 1.0, "name": "INCONNU"}
        assert applied(entry, {}) == entry

    def test_une_ligne_qui_n_est_pas_un_article_reste_intacte(self) -> None:
        entry = {"role": "total", "amount": 12.0}
        assert applied(entry, {ORIGINAL: Split("WASA FIBRES", "230G")}) == entry

    def test_la_decoration_d_enseigne_ne_fait_pas_partie_du_conditionnement(
        self,
    ) -> None:
        """« *230G » désigne 230 g : l'astérisque est une marque de rayon.
        Le champ est dérivé, aligné sur rien — seule l'absence d'invention
        compte."""
        assert accepted(ORIGINAL, Split("WASA FIBRES", "230G"))
        assert accepted("#1L JUS ORANGE", Split("JUS ORANGE", "1L"))

    def test_un_conditionnement_inteligible_reste_refuse(self) -> None:
        assert not accepted(ORIGINAL, Split("WASA FIBRES", "2306"))


class TestInconsistencies:
    def test_un_token_coupe_ici_et_garde_la_est_signale(self) -> None:
        """Le défaut qu'on répare, retourné contre le correctif : si la
        découpe reproduit le pile-ou-face, il faut le voir."""
        table = {
            "*230G WASA FIBRES": Split("WASA FIBRES", "230G"),
            "*230G PAT BRISE SS": Split("*230G PAT BRISE SS", "230G"),
        }
        assert inconsistencies(table) == {"230G": (1, 2)}

    def test_un_token_toujours_coupe_ne_l_est_pas(self) -> None:
        table = {
            "*230G WASA FIBRES": Split("WASA FIBRES", "230G"),
            "*230G PAT BRISE SS": Split("PAT BRISE SS", "230G"),
        }
        assert inconsistencies(table) == {}

    def test_un_calibre_interieur_ne_compte_pas(self) -> None:
        """Il n'est pas en frontière, donc aucune décision de découpe n'a été
        prise : le comparer à une coupe n'aurait pas de sens."""
        table = {
            "BEURRE 250G DOUX": Split("BEURRE 250G DOUX", "250G"),
            "BAGUETTE 250G": Split("BAGUETTE", "250G"),
        }
        assert inconsistencies(table) == {}


class TestGoldenItem:
    def test_le_nom_et_le_conditionnement_remplacent_l_article(self) -> None:
        item = {"name": ORIGINAL, "amount": 1.89, "discount": 0}
        assert golden_item(item, {ORIGINAL: Split("WASA FIBRES", "230G")}) == {
            "name": "WASA FIBRES",
            "amount": 1.89,
            "discount": 0,
            "size": "230G",
        }

    def test_un_article_sans_conditionnement_ne_gagne_pas_le_champ(self) -> None:
        item = {"name": "PAIN", "amount": 1.0, "discount": 0}
        assert golden_item(item, {"PAIN": Split("PAIN", None)}) == item

    def test_un_nom_absent_de_la_table_reste_intact(self) -> None:
        item = {"name": "INCONNU", "amount": 1.0, "discount": 0}
        assert golden_item(item, {}) == item
