"""Sélection de l'enseigne et de la ligne de date par le tagger de rôles."""

from __future__ import annotations

import numpy as np
import pytest

from annotate.schema import DATE_LINE, ROLES, STORE
from reference.header_ml import date_of, store_of
from reference.lines import PhysicalLine, Word
from reference.store_gazetteer import Gazetteer

# Un répertoire de test, pour que ces cas ne dépendent pas de l'artefact
# construit depuis le corpus.
KNOWN = Gazetteer({"QUICK": "Quick", "CARREFOUR": "Carrefour"})


def line(text: str) -> PhysicalLine:
    return PhysicalLine(
        words=[
            Word(text=token, left=0, top=0, right=10, bottom=10, confidence=None)
            for token in text.split()
        ]
    )


def probabilities(*rows: dict[str, float]) -> np.ndarray:
    matrix = np.zeros((len(rows), len(ROLES)))
    for index, row in enumerate(rows):
        for role, value in row.items():
            matrix[index][ROLES.index(role)] = value
    return matrix


LINES = [line("Burger Restaurant"), line("Quick"), line("Le 24/02/2017 a 10:49")]


def test_l_enseigne_est_la_ligne_designee_pas_la_premiere() -> None:
    """51 tickets sur 500 ont un slogan ou une adresse en première ligne."""
    scores = probabilities({STORE: 0.1}, {STORE: 0.9}, {})
    assert store_of(LINES, scores, Gazetteer({})) == "Quick"


def test_aucune_enseigne_si_le_tagger_hesite() -> None:
    """Mieux vaut pas d'enseigne qu'une ligne prise au hasard — tant qu'aucun
    nom connu n'est en vue."""
    scores = probabilities({STORE: 0.3}, {STORE: 0.4}, {})
    assert store_of(LINES, scores, Gazetteer({})) is None


def test_un_nom_connu_normalise_la_ligne_designee() -> None:
    """`E.Leclerc L`, `ToysMus` : la ligne recopiée telle quelle garde ce que
    l'OCR y a laissé. Le répertoire rend la graphie connue."""
    scores = probabilities({}, {STORE: 0.9}, {})
    lines = [line("Burger Restaurant"), line("Quick Rochefort"), line("x")]
    assert store_of(lines, scores, KNOWN) == "Quick"


def test_une_ligne_designee_inconnue_est_rendue_telle_quelle() -> None:
    scores = probabilities({STORE: 0.9}, {}, {})
    lines = [line("BOUCHERIE PHILIBERTINE"), line("Quick"), line("x")]
    assert store_of(lines, scores, KNOWN) == "BOUCHERIE PHILIBERTINE"


def test_le_repertoire_ne_choisit_jamais_la_ligne() -> None:
    """Le modèle désigne « -SP », le répertoire connaît « Quick » sur la
    ligne d'à côté : c'est le modèle qui décide, la ligne désignée est rendue."""
    scores = probabilities({STORE: 0.2}, {STORE: 0.8}, {})
    lines = [line("Quick"), line("-SP"), line("Le 24/02/2017 a 10:49")]
    assert store_of(lines, scores, KNOWN) == "-SP"


def test_sans_ligne_designee_aucun_nom_n_est_cherche_ailleurs() -> None:
    """« www.auchan.fr » en tête et le tagger qui hésite : pas d'enseigne.
    Un lexique ne remplace pas le modèle."""
    known = Gazetteer({"AUCHAN": "Auchan"})
    scores = probabilities({STORE: 0.3}, {}, {"item": 0.9})
    lines = [line("STALINGRAD"), line("www.auchan.fr"), line("LAIT 1,20")]
    assert store_of(lines, scores, known) is None


def test_la_date_est_lue_sur_la_ligne_designee() -> None:
    scores = probabilities({}, {}, {DATE_LINE: 0.9})
    assert date_of(LINES, scores) == "2017-02-24"


def test_la_date_reste_cherchee_partout_si_la_ligne_designee_n_en_porte_pas() -> None:
    """Le tagger peut se tromper de ligne ; il ne doit pas faire perdre une
    date que les règles savaient lire."""
    scores = probabilities({DATE_LINE: 0.9}, {}, {})
    assert date_of(LINES, scores) == "2017-02-24"


def test_sans_ligne_aucune_date() -> None:
    assert date_of([], probabilities()) is None


@pytest.mark.parametrize("role", [STORE, DATE_LINE])
def test_un_ticket_vide_ne_designe_rien(role: str) -> None:
    assert store_of([], probabilities()) is None
