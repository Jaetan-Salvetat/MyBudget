"""Lecture de la date d'un ticket.

Premier poste d'erreur mesuré sur T1-test : 153 tickets sur 500. Deux causes,
une racine — le motif exigeait quatre chiffres d'année et n'avait aucune
borne à droite, donc il ratait les tickets qui impriment l'année sur deux
chiffres, et avalait l'heure sur les autres.
"""

from __future__ import annotations

import pytest

from reference.lines import PhysicalLine, Word
from reference.structure import _find_date


def line(text: str) -> PhysicalLine:
    return PhysicalLine(
        words=[
            Word(text=token, left=0, top=0, right=10, bottom=10, confidence=None)
            for token in text.split()
        ]
    )


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("Le 24/02/2017 a 10:49", "2017-02-24"),
        ("24.02.2017", "2017-02-24"),
        ("0001 004 000035 24/02/2017 10:49:08", "2017-02-24"),
    ],
)
def test_annee_sur_quatre_chiffres(text: str, expected: str) -> None:
    assert _find_date([line(text)]) == expected


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("18/12/16", "2016-12-18"),
        ("Ticket du 18/12/16 a 14:02", "2016-12-18"),
        ("13/03/17 20:30", "2017-03-13"),
    ],
)
def test_annee_sur_deux_chiffres(text: str, expected: str) -> None:
    """87 tickets de T1-test n'impriment que deux chiffres d'année."""
    assert _find_date([line(text)]) == expected


def test_l_heure_collee_ne_devient_pas_l_annee() -> None:
    """« 01/07/26 19:04:07 » compacté donnait l'année 2619 : une année hors
    de toute plage plausible doit faire relire les deux premiers chiffres."""
    assert _find_date([line("01/07/26 19:04:07 0004431 Pos 101")]) == "2026-07-01"


def test_une_annee_aberrante_est_relue_sur_deux_chiffres() -> None:
    assert _find_date([line("13/03/1720:30:12")]) == "2017-03-13"


def test_aucune_date() -> None:
    assert _find_date([line("MERCI DE VOTRE VISITE")]) is None


def test_la_premiere_date_lisible_gagne() -> None:
    lines = [line("CARREFOUR"), line("24/02/2017"), line("31/12/2018")]
    assert _find_date(lines) == "2017-02-24"


def test_l_ocr_confond_o_et_zero() -> None:
    assert _find_date([line("o9/o3/2o17")]) == "2017-03-09"


@pytest.mark.parametrize(
    "text",
    [
        "Tel : 05.46.27.02.12",
        "Tel: 05-62-40-12-30",
        "TEL.05.49.28.31.44",
        "TVA 20.00 5.50 2.10",
        "0001 004 000035",
    ],
)
def test_ne_confond_pas_un_numero_avec_une_date(text: str) -> None:
    """Un téléphone français est une suite de paires séparées par des points :
    accepter une année sur deux chiffres sans exiger de frontière en fait une
    date (« 27.02.12 »), et c'est la moitié du corpus qui bascule."""
    assert _find_date([line(text)]) is None


def test_une_date_apres_un_numero_reste_lisible() -> None:
    lines = [line("Tel : 05.46.27.02.12"), line("24/02/2017")]
    assert _find_date(lines) == "2017-02-24"


@pytest.mark.parametrize("text", ["32/02/2017", "24/13/2017", "00/02/2017"])
def test_rejette_un_jour_ou_un_mois_impossible(text: str) -> None:
    assert _find_date([line(text)]) is None


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("001 / 000003 / 07/01/2017 / 18:12:36", "2017-01-07"),
        ("MERCREDI 08-03-2017 12:42:27 (RESTAU 2 )", "2017-03-08"),
        ("Caisse 3 - 07/01/2017", "2017-01-07"),
    ],
)
def test_date_entouree_de_separateurs(text: str, expected: str) -> None:
    """Le garde-fou anti-téléphone ne doit pas rejeter une date encadrée par
    les séparateurs d'un pied de ticket."""
    assert _find_date([line(text)]) == expected


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("DIM 18 DECEMBRE 2016", "2016-12-18"),
        ("MARDI 25 MAI 2004 13: 19: 02", "2004-05-25"),
        ("MER 14 DEC 2016", "2016-12-14"),
        ("26/MAR/17", "2017-03-26"),
        ("13juin17", "2017-06-13"),
        ("Le 1er AOUT 2017", "2017-08-01"),
        ("5 fevrier 2016", "2016-02-05"),
    ],
)
def test_mois_en_lettres(text: str, expected: str) -> None:
    """85 tickets de T1-test impriment le mois en toutes lettres ou abrégé."""
    assert _find_date([line(text)]) == expected


def test_un_mois_en_lettres_ne_sort_pas_d_un_jour_de_semaine() -> None:
    assert _find_date([line("MARDI OUVERT")]) is None


def test_la_forme_numerique_prime_sur_les_lettres() -> None:
    lines = [line("MERCREDI 08-03-2017")]
    assert _find_date(lines) == "2017-03-08"


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("0002 G04 000643 22/02/2017 12:21:45", "2017-02-22"),
        ("9999004500103081611071906 caisse", None),
    ],
)
def test_un_code_de_caisse_n_est_pas_un_telephone(
    text: str, expected: str | None
) -> None:
    """Un ticket est plein de suites de dix chiffres commençant par zéro :
    masquer sans exiger de séparateur effaçait la date qui les suit."""
    assert _find_date([line(text)]) == expected


def test_mois_accentue() -> None:
    assert _find_date([line("dimanche 28 août 2016 - 19:56")]) == "2016-08-28"


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("7/10/15 16:22 0071 06 0080 3", "2015-10-07"),
        ("TICKET : 1-06348 DT 14/1/17 11H03", "2017-01-14"),
        ("7.11.16 19:06 0045 01 0308 211", "2016-11-07"),
    ],
)
def test_jour_ou_mois_sur_un_chiffre(text: str, expected: str) -> None:
    assert _find_date([line(text)]) == expected
