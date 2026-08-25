"""Sélection de l'enseigne et de la ligne de date par le tagger de rôles."""

from __future__ import annotations

import numpy as np
import pytest

from annotate.schema import DATE_LINE, ROLES, STORE
from reference.header_ml import date_of, store_of
from reference.lines import PhysicalLine, Word


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
    assert store_of(LINES, scores) == "Quick"


def test_aucune_enseigne_si_le_tagger_hesite() -> None:
    """Mieux vaut pas d'enseigne qu'une ligne prise au hasard."""
    scores = probabilities({STORE: 0.3}, {STORE: 0.4}, {})
    assert store_of(LINES, scores) is None


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
