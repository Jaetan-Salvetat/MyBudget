"""Le classifieur d'enseigne : une question posée au ticket entier.

Le tagger désigne une ligne ; sur les tickets où l'enseigne n'est qu'un
domaine web ou un pied de ticket, aucune ligne n'est « l'enseigne » et il ne
peut rien désigner. Le classifieur lit tout le ticket et rend l'enseigne parmi
un ensemble fermé, ou « autre » — et c'est alors la ligne désignée qui parle.
"""

from __future__ import annotations

import zlib

from reference.lines import PhysicalLine, Word
from reference.store_classifier import (
    BUCKETS,
    OTHER,
    StoreClassifier,
    ticket_features,
)


def line(text: str) -> PhysicalLine:
    return PhysicalLine(
        words=[
            Word(text=token, left=0, top=0, right=10, bottom=10, confidence=None)
            for token in text.split()
        ]
    )


def bucket(token: str) -> int:
    return zlib.crc32(token.encode()) % BUCKETS


class TestFeatures:
    def test_les_mots_et_les_bigrammes_normalises_du_ticket(self) -> None:
        features = ticket_features([line("www.auchan.fr"), line("Caisse 3")])
        assert {
            bucket("WWW"),
            bucket("AUCHAN"),
            bucket("FR"),
            bucket("WWW AUCHAN"),
        } <= features
        assert bucket("CAISSE 3") in features

    def test_les_bigrammes_ne_traversent_pas_les_lignes(self) -> None:
        features = ticket_features([line("AUCHAN"), line("PESSAC")])
        assert bucket("AUCHAN PESSAC") not in features

    def test_un_ticket_vide_n_a_pas_de_trait(self) -> None:
        assert ticket_features([]) == set()


def classifier() -> StoreClassifier:
    return StoreClassifier(
        classes=[OTHER, "Auchan", "LIDL"],
        intercepts=[0.5, 0.0, 0.0],
        weights=[
            {},
            {bucket("AUCHAN"): 2.0, bucket("WAAOH"): 1.5},
            {bucket("LIDL"): 2.0},
        ],
    )


class TestPrediction:
    def test_l_enseigne_soutenue_par_le_ticket(self) -> None:
        assert (
            classifier().predict([line("STALINGRAD"), line("www.auchan.fr")])
            == "Auchan"
        )

    def test_autre_quand_rien_ne_soutient_une_enseigne(self) -> None:
        assert classifier().predict([line("BOUCHERIE PHILIBERTINE")]) is None

    def test_la_plus_forte_gagne(self) -> None:
        lines = [line("www.auchan.fr"), line("VOTRE COMPTE WAAOH"), line("LIDL")]
        assert classifier().predict(lines) == "Auchan"

    def test_un_ticket_vide_est_autre(self) -> None:
        assert classifier().predict([]) is None


class TestSerialisation:
    def test_aller_retour_json(self) -> None:
        data = classifier().to_json()
        assert data["buckets"] == BUCKETS
        loaded = StoreClassifier.from_json(data)
        assert loaded.predict([line("LIDL")]) == "LIDL"
        assert loaded.to_json() == data

    def test_les_poids_sont_arrondis_a_l_export(self) -> None:
        model = StoreClassifier(
            classes=[OTHER, "X"],
            intercepts=[0.123456789, 0.0],
            weights=[{}, {1: 1.00004}],
        )
        data = model.to_json()
        assert data["intercepts"][0] == 0.1235
        assert data["weights"][1]["1"] == 1.0
