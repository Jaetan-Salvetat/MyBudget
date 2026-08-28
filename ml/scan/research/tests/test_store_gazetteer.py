"""Le répertoire des enseignes : reconnaître au lieu de recopier.

Deux exigences opposées le tiennent. Il doit retrouver une enseigne sous un
OCR abîmé — c'est tout son intérêt — sans jamais nommer une enseigne là où le
ticket parle d'autre chose : une rue « Cours Maréchal Leclerc », un mot
« TOTAL », un site web en pied de ticket.
"""

from __future__ import annotations

from reference.store_gazetteer import (
    Gazetteer,
    _discriminant,
    normalize,
)

ENTRIES = {
    "CARREFOUR MARKET": "Carrefour market",
    "CARREFOUR": "Carrefour",
    "E LECLERC": "E.Leclerc",
    "MCDONALDS": "McDonald's",
    "U": "U",
}


def gazetteer() -> Gazetteer:
    return Gazetteer(dict(ENTRIES))


class TestNormalisation:
    def test_les_accents_et_la_casse_disparaissent(self):
        assert normalize("Intermarché") == "INTERMARCHE"

    def test_la_ponctuation_devient_une_frontiere(self):
        assert normalize("E.Leclerc") == "E LECLERC"

    def test_les_espaces_multiples_se_reduisent(self):
        assert normalize("  SUPER   U  ") == "SUPER U"


class TestReconnaissance:
    def test_un_nom_exact(self):
        assert gazetteer().match("Carrefour") == "Carrefour"

    def test_le_nom_le_plus_long_gagne(self):
        """« CARREFOUR MARKET » ne doit pas rendre « Carrefour » : les deux
        sont au répertoire et l'enseigne complète est la bonne."""
        assert gazetteer().match("CARREFOUR MARKET") == "Carrefour market"

    def test_un_nom_noye_dans_la_ligne(self):
        assert gazetteer().match("* E.LECLERC ROCHEFORT *") == "E.Leclerc"

    def test_un_nom_abime_par_l_ocr(self):
        """`McDonald's` lu `McDona1ds` reste reconnaissable."""
        assert gazetteer().match("McDona1ds") == "McDonald's"

    def test_une_ligne_inconnue_ne_rend_rien(self):
        assert gazetteer().match("BOUCHERIE PHILIBERTINE") is None

    def test_une_ligne_vide_ne_rend_rien(self):
        assert gazetteer().match("   ") is None


class TestFauxAmis:
    def test_une_entree_courte_doit_etre_la_ligne_entiere(self):
        """« U » est une enseigne ; le trouver dans « RUE DU PORT » n'en fait
        pas un magasin."""
        assert gazetteer().match("RUE DU PORT") is None
        assert gazetteer().match("U") == "U"

    def test_un_nom_trop_deforme_n_est_plus_le_nom(self):
        assert gazetteer().match("MCDXXXXXX") is None


class TestDiscriminance:
    """Un nom n'entre au répertoire que si le trouver annonce vraiment cette
    enseigne. Aucune liste noire : le corpus tranche."""

    def test_un_mot_de_ticket_est_ecarte(self):
        """« TOTAL » est une enseigne de station-service, et le mot le plus
        fréquent d'un ticket de caisse."""
        receipts = [
            ("TOTAL", ["TOTAL", "TOTAL A PAYER 12 00"]),
            ("CARREFOUR", ["CARREFOUR", "TOTAL A PAYER 3 00"]),
            ("LIDL", ["LIDL", "TOTAL 9 00"]),
            ("MONOPRIX", ["MONOPRIX", "TOTAL 4 00"]),
        ]
        entries = dict.fromkeys(["TOTAL", "CARREFOUR", "LIDL", "MONOPRIX"], None)
        kept = _discriminant(entries, receipts)
        assert "TOTAL" not in kept
        assert {"CARREFOUR", "LIDL", "MONOPRIX"} <= kept

    def test_un_nom_unique_entre_sans_preuve_supplementaire(self):
        """Une boulangerie vue une seule fois ne collisionne avec rien."""
        receipts = [
            ("BOULANGERIE DUPONT", ["BOULANGERIE DUPONT", "PAIN 1 20"]),
            ("LIDL", ["LIDL", "PAIN 0 90"]),
        ]
        kept = _discriminant(dict.fromkeys(["BOULANGERIE DUPONT"], None), receipts)
        assert "BOULANGERIE DUPONT" in kept

    def test_un_nom_jamais_vu_sur_une_ligne_reste_dehors(self):
        kept = _discriminant(
            dict.fromkeys(["ENSEIGNE FANTOME"], None), [("LIDL", ["LIDL"])]
        )
        assert kept == set()
