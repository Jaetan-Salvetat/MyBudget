"""Rattachement du libellé à son article via le tagger de rôles."""

from __future__ import annotations

import numpy as np

from annotate.schema import ITEM_LABEL, ROLES
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


def label_scores(*values: float) -> np.ndarray:
    matrix = np.zeros((len(values), len(ROLES)))
    for index, value in enumerate(values):
        matrix[index][ROLES.index(ITEM_LABEL)] = value
    return matrix


LINES = [line("PREM Litiere AGGLO 12KG"), line("16,99 EUR"), line("2200017 CITIZEN")]


def test_un_libelle_vide_prend_la_ligne_designee_au_dessus() -> None:
    items = [ExtractedItem(name="EUR", amount=16.99, discount=0.0, line_index=1)]
    [item] = relabel(items, LINES, label_scores(0.9, 0.0, 0.0))
    assert item.name == "PREM Litiere AGGLO 12KG"


def test_un_libelle_deja_parlant_n_est_pas_ecrase() -> None:
    """Le tagger se trompe une fois sur six ; il corrige, il n'arbitre pas."""
    items = [
        ExtractedItem(name="BAGUETTE 125G", amount=16.99, discount=0.0, line_index=1)
    ]
    [item] = relabel(items, LINES, label_scores(0.9, 0.0, 0.0))
    assert item.name == "BAGUETTE 125G"


def test_le_tagger_hesitant_ne_change_rien() -> None:
    items = [ExtractedItem(name="EUR", amount=16.99, discount=0.0, line_index=1)]
    [item] = relabel(items, LINES, label_scores(0.3, 0.0, 0.0))
    assert item.name == "EUR"


def test_une_ligne_de_libelle_ne_sert_qu_une_fois() -> None:
    """Deux articles ne partagent pas un nom."""
    lines = [line("PAIN COMPLET"), line("2,50 EUR"), line("1,20 EUR")]
    items = [
        ExtractedItem(name="EUR", amount=2.50, discount=0.0, line_index=1),
        ExtractedItem(name="EUR", amount=1.20, discount=0.0, line_index=2),
    ]
    first, second = relabel(items, lines, label_scores(0.9, 0.0, 0.0))
    assert first.name == "PAIN COMPLET"
    assert second.name == "EUR"


def test_un_article_sans_ligne_source_est_ignore() -> None:
    items = [ExtractedItem(name="EUR", amount=16.99, discount=0.0)]
    [item] = relabel(items, LINES, label_scores(0.9, 0.0, 0.0))
    assert item.name == "EUR"


def test_sans_prediction_rien_ne_bouge() -> None:
    items = [ExtractedItem(name="EUR", amount=16.99, discount=0.0, line_index=1)]
    assert relabel(items, LINES, np.zeros((0, len(ROLES))))[0].name == "EUR"
