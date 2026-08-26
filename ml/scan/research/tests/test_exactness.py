"""Un ticket est bon, ou il ne l'est pas — et toutes les erreurs ne se valent
pas.

`count_edits` compte des montants et ignore les libellés : une extraction peut
être à zéro correction avec tous les noms décalés d'une ligne. Cette
métrique-ci exige que chaque article soit apparié sur le couple (nom, montant
net), et sépare ce que l'utilisateur peut rattraper de ce qu'il ne verra
jamais.
"""

from __future__ import annotations

from bench.exactness import (
    AMOUNT,
    DATE,
    EXTRA,
    LABEL,
    MISSING,
    STORE,
    TOTAL,
    ExtractedName,
    compare_items,
    name_matches,
    receipt_exactness,
    store_matches,
)


def item(name: str, amount: float, discount: float = 0.0) -> ExtractedName:
    return ExtractedName(name=name, amount=amount, discount=discount)


expected = item


class TestNameMatches:
    def test_libelles_identiques(self) -> None:
        assert name_matches("PAIN COMPLET", "PAIN COMPLET")

    def test_tolere_les_degats_ocr(self) -> None:
        """L'OCR abîme des caractères ; on mesure le rattachement, pas l'OCR."""
        assert name_matches(
            "JBON CRU DENTEL.AOSTE 120GENU", "JBON CRU DENTEL.AOSTE 120GENV"
        )

    def test_ignore_casse_et_ponctuation(self) -> None:
        assert name_matches("*1/2 Baguette 125g", "1 2 BAGUETTE 125G")

    def test_refuse_un_libelle_d_un_autre_article(self) -> None:
        assert not name_matches("PAIN COMPLET", "LESSIVE FEUILLE X80")

    def test_refuse_un_mot_que_la_verite_ne_porte_pas(self) -> None:
        """La classe de TVA, la quantité ou un code imprimé dans une autre
        colonne n'a rien à faire dans un nom : c'est lui qui part en
        catégorisation, et l'utilisateur le lit tel quel."""
        assert not name_matches("EMMENTAL RAPE 2", "EMMENTAL RAPE")
        assert not name_matches("SAFE Maison toil D", "SAFE Maison toil")
        assert not name_matches("MPDC MARQUE PAG 2 20 1", "MPDC MARQUE PAG")
        assert not name_matches("SANDW 6015", "SANDW")

    def test_tolere_un_libelle_plus_court_que_la_verite(self) -> None:
        """L'OCR coupe une ligne, la colonne coupe une référence : le nom
        reste celui de l'article. Ce qui manque ne trompe personne, ce qui
        est en trop si."""
        assert name_matches("M GIANT", "1 M GIANT")
        assert name_matches(
            "W TEE SHIRT FLUIDE COL", "W TEE SHIRT FLUIDE COL 685522 BLEU L"
        )

    def test_degat_ocr_a_nombre_de_mots_egal_reste_tolere(self) -> None:
        assert name_matches("140G 1ARTE POMMES", "140G TARTE POMMES")
        assert name_matches(
            "OEUFS PPA LABEL ROUGE U BTE XS", "OEUFS PPA LABEL ROUGE U BTE X6"
        )

    def test_refuse_un_libelle_qui_ne_nomme_rien(self) -> None:
        assert not name_matches("x EUR", "PREM Litiere AGGLO 12KG")
        assert not name_matches("0,792 kg 2,65 kg", "POIRE CONFERENCE")

    def test_refuse_un_libelle_vide_de_sens(self) -> None:
        """Le prix imprimé sur sa propre ligne laisse un libellé qui ne
        nomme rien — c'est le défaut qui envoie un ticket entier dans la
        mauvaise catégorie."""
        assert not name_matches("EUR", "PREM Litiere AGGLO 12KG")


class TestCompareItems:
    def test_tout_juste(self) -> None:
        got = [item("PAIN", 2.50), item("LAIT", 1.20)]
        assert compare_items(got, [expected("PAIN", 2.50), expected("LAIT", 1.20)]) == []

    def test_un_nom_faux_sur_un_montant_juste_est_un_libelle_faux(self) -> None:
        """L'utilisateur ne voit pas que ce nom appartient à l'article
        d'à côté : la somme tombe juste et la ligne a l'air normale."""
        got = [item("PAIN", 2.50), item("EUR", 1.20)]
        assert compare_items(
            got, [expected("PAIN", 2.50), expected("LAIT", 1.20)]
        ) == [LABEL]

    def test_un_montant_faux_sur_un_nom_juste_est_un_montant_faux(self) -> None:
        """Celui-là se corrige en deux gestes : le nom désigne la ligne du
        ticket à relire."""
        got = [item("PAIN", 2.50), item("LAIT", 9.99)]
        assert compare_items(
            got, [expected("PAIN", 2.50), expected("LAIT", 1.20)]
        ) == [AMOUNT]

    def test_libelles_permutes(self) -> None:
        """Zéro correction pour `count_edits`, deux libellés faux ici."""
        got = [item("LAIT", 2.50), item("PAIN", 1.20)]
        assert compare_items(
            got, [expected("PAIN", 2.50), expected("LAIT", 1.20)]
        ) == [LABEL, LABEL]

    def test_article_manquant(self) -> None:
        assert compare_items(
            [item("PAIN", 2.50)], [expected("PAIN", 2.50), expected("LAIT", 1.20)]
        ) == [MISSING]

    def test_article_en_trop(self) -> None:
        got = [item("PAIN", 2.50), item("LAIT", 1.20)]
        assert compare_items(got, [expected("PAIN", 2.50)]) == [EXTRA]

    def test_un_article_faux_de_bout_en_bout_manque_et_est_en_trop(self) -> None:
        """Ni le nom ni le montant ne concordent : rien ne dit que ces deux
        articles sont le même, et la métrique ne le devine pas."""
        assert compare_items(
            [item("SAVON", 9.99)], [expected("PAIN", 2.50)]
        ) == [EXTRA, MISSING]

    def test_la_remise_compte_dans_le_montant_net(self) -> None:
        got = [item("PAIN", 2.50, discount=0.50)]
        assert compare_items(got, [expected("PAIN", 2.00)]) == []
        assert compare_items(got, [expected("PAIN", 2.50)]) == [AMOUNT]

    def test_deux_articles_de_meme_prix_et_meme_nom(self) -> None:
        got = [item("PAIN", 2.50), item("PAIN", 2.50)]
        assert compare_items(got, [expected("PAIN", 2.50), expected("PAIN", 2.50)]) == []

    def test_appariement_prefere_le_couple_complet(self) -> None:
        """Deux articles au même prix, libellés différents : l'appariement
        ne doit pas fabriquer deux libellés faux à cause de l'ordre."""
        got = [item("LAIT", 2.50), item("PAIN", 2.50)]
        assert compare_items(got, [expected("PAIN", 2.50), expected("LAIT", 2.50)]) == []


GOLDEN = {
    "receipt": {
        "store": "CARREFOUR CITY",
        "date": "2017-02-24",
        "total": 3.70,
        "items": [
            {"name": "PAIN", "amount": 2.50, "discount": 0},
            {"name": "LAIT", "amount": 1.20, "discount": 0},
        ],
    }
}
ITEMS = [item("PAIN", 2.50), item("LAIT", 1.20)]


class TestStoreMatches:
    def test_le_logo_lu_partiellement_reste_la_bonne_enseigne(self) -> None:
        """L'OCR ne lit souvent que le logo (« city ») là où le golden nomme
        l'enseigne complète."""
        assert store_matches("city", "CARREFOUR CITY")

    def test_deux_enseignes_differentes(self) -> None:
        assert not store_matches("MAXI ZOO", "INTERMARCHE")

    def test_enseigne_illisible(self) -> None:
        assert not store_matches(None, "CARREFOUR CITY")


class TestReceiptExactness:
    def test_tout_juste(self) -> None:
        result = receipt_exactness("CARREFOUR CITY", "2017-02-24", 3.70, ITEMS, GOLDEN)
        assert result.exact and result.wrong == [] and result.silent == []

    def test_une_date_fausse_suffit_a_invalider(self) -> None:
        """« 01/07/26 19:04 » lu « 2619-07-01 » : le budget tombe dans le
        mauvais mois, tout le reste peut bien être juste."""
        result = receipt_exactness("CARREFOUR CITY", "2619-07-01", 3.70, ITEMS, GOLDEN)
        assert not result.exact and result.wrong == [DATE]

    def test_une_enseigne_fausse_suffit_a_invalider(self) -> None:
        result = receipt_exactness("MAXI ZOO", "2017-02-24", 3.70, ITEMS, GOLDEN)
        assert result.wrong == [STORE]

    def test_un_total_faux_suffit_a_invalider(self) -> None:
        result = receipt_exactness("CARREFOUR CITY", "2017-02-24", 58.98, ITEMS, GOLDEN)
        assert result.wrong == [TOTAL]

    def test_les_metadonnees_fausses_ne_sont_pas_silencieuses(self) -> None:
        """L'utilisateur relit l'enseigne, la date et le total en haut de
        l'écran : il les corrige. Ce n'est pas la même gravité."""
        result = receipt_exactness("MAXI ZOO", "2619-07-01", 58.98, ITEMS, GOLDEN)
        assert result.silent == []

    def test_un_libelle_faux_est_silencieux(self) -> None:
        wrong_label = [item("PAIN", 2.50), item("EUR", 1.20)]
        result = receipt_exactness(
            "CARREFOUR CITY", "2017-02-24", 3.70, wrong_label, GOLDEN
        )
        assert result.wrong == [LABEL] and result.silent == [LABEL]

    def test_un_article_manquant_est_silencieux(self) -> None:
        result = receipt_exactness(
            "CARREFOUR CITY", "2017-02-24", 3.70, [item("PAIN", 2.50)], GOLDEN
        )
        assert result.silent == [MISSING]

    def test_les_articles_sont_comptes_un_a_un(self) -> None:
        """Le ticket est faux une fois ; le bench a besoin de savoir combien
        d'articles ont dérapé."""
        permuted = [item("LAIT", 2.50), item("PAIN", 1.20)]
        result = receipt_exactness(
            "CARREFOUR CITY", "2017-02-24", 3.70, permuted, GOLDEN
        )
        assert result.counts == {LABEL: 2}

    def test_cumule_toutes_les_divergences(self) -> None:
        result = receipt_exactness("MAXI ZOO", "2619-07-01", 58.98, [], GOLDEN)
        assert result.wrong == [STORE, DATE, TOTAL, MISSING]
