"""Rattachement du libellé à son article, décidé par le modèle de lien."""

from __future__ import annotations

import numpy as np

from reference.labels_ml import relabel
from reference.lines import PhysicalLine, Word
from reference.structure import ExtractedItem


def line(text: str) -> PhysicalLine:
    return PhysicalLine(
        words=[
            Word(text=token, left=0, top=0, right=10, bottom=10, confidence=None)
            for token in text.split()
        ]
    )


def offsets(*values: int) -> np.ndarray:
    return np.array(values)


LINES = [line("PREM Litiere AGGLO 12KG"), line("16,99 EUR"), line("2200017 CITIZEN")]


def test_le_libelle_vient_de_la_ligne_a_la_distance_predite() -> None:
    items = [ExtractedItem(name="EUR", amount=16.99, discount=0.0, line_index=1)]
    [item] = relabel(items, LINES, offsets(0, 1, 0))
    assert item.name == "PREM Litiere AGGLO 12KG"


def test_le_libelle_predit_prime_sur_celui_de_la_ligne_du_prix() -> None:
    """Le modèle décide : quoi qu'ait ramassé la règle sur la ligne du prix
    — une pesée, une quantité, un code — c'est la ligne désignée qui nomme."""
    items = [
        ExtractedItem(
            name="0,792 kg 2,65 EUR/kg", amount=16.99, discount=0.0, line_index=1
        )
    ]
    [item] = relabel(items, LINES, offsets(0, 1, 0))
    assert item.name == "PREM Litiere AGGLO 12KG"


def test_une_distance_nulle_laisse_le_libelle_des_regles() -> None:
    """Le modèle place le libellé sur la ligne du prix : rien à rattacher."""
    items = [
        ExtractedItem(name="BAGUETTE 125G", amount=16.99, discount=0.0, line_index=1)
    ]
    [item] = relabel(items, LINES, offsets(0, 0, 0))
    assert item.name == "BAGUETTE 125G"


def test_une_ligne_de_libelle_ne_sert_qu_une_fois() -> None:
    """Deux articles ne partagent pas un nom."""
    lines = [line("PAIN COMPLET"), line("2,50 EUR"), line("1,20 EUR")]
    items = [
        ExtractedItem(name="EUR", amount=2.50, discount=0.0, line_index=1),
        ExtractedItem(name="EUR", amount=1.20, discount=0.0, line_index=2),
    ]
    first, second = relabel(items, lines, offsets(0, 1, 2))
    assert first.name == "PAIN COMPLET"
    assert second.name == "EUR"


def test_une_ligne_qui_ne_nomme_rien_n_est_pas_rattachee() -> None:
    lines = [line("*"), line("2,50 EUR")]
    items = [ExtractedItem(name="EUR", amount=2.50, discount=0.0, line_index=1)]
    [item] = relabel(items, lines, offsets(0, 1))
    assert item.name == "EUR"


def test_une_distance_qui_sort_du_ticket_ne_change_rien() -> None:
    items = [ExtractedItem(name="EUR", amount=16.99, discount=0.0, line_index=0)]
    [item] = relabel(items, LINES, offsets(2, 0, 0))
    assert item.name == "EUR"


def test_un_article_sans_ligne_source_est_ignore() -> None:
    items = [ExtractedItem(name="EUR", amount=16.99, discount=0.0)]
    [item] = relabel(items, LINES, offsets(0, 1, 0))
    assert item.name == "EUR"


def test_sans_prediction_rien_ne_bouge() -> None:
    items = [ExtractedItem(name="EUR", amount=16.99, discount=0.0, line_index=1)]
    assert relabel(items, LINES, np.zeros(0, dtype=int))[0].name == "EUR"
