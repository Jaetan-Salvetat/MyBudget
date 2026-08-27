"""Le repli des rôles du tagger sur les cinq classes du décodeur.

Le décodeur raisonne en article / remise / référence / paiement / ignoré ; le
tagger répond en neuf rôles sur toutes les lignes. Le repli est le seul
endroit où les deux vocabulaires se rencontrent, et s'y tromper décalerait
silencieusement toutes les probabilités du décodage.
"""

from __future__ import annotations

import numpy as np
from test_structure import receipt_lines

from reference.decode_roles import DECODER_CLASSES, decoder_probabilities
from reference.line_features import priced_lines
from reference.line_labels import DISCOUNT, IGNORE, ITEM, PAYMENT, TAGGER_ROLES, TOTAL
from reference.structure import merge_price_fragments

ROLE_COLUMN = {role: index for index, role in enumerate(TAGGER_ROLES)}


def _one_hot(roles: list[str]) -> np.ndarray:
    probabilities = np.zeros((len(roles), len(TAGGER_ROLES)))
    for row, role in enumerate(roles):
        probabilities[row, ROLE_COLUMN[role]] = 1.0
    return probabilities


def _tokens(text: str) -> list[tuple[str, int]]:
    """Les mots d'une ligne, posés côte à côte : le dernier prix reste le plus
    à droite, ce que `priced_lines` cherche."""
    tokens = []
    column = 0
    for piece in text.split():
        tokens.append((piece, column))
        column += len(piece) + 1
    return tokens


def _priced(texts: list[str]):
    lines = receipt_lines([_tokens(text) for text in texts])
    return priced_lines([merge_price_fragments(line) for line in lines])


def test_les_lignes_sans_prix_ne_sont_pas_decodees():
    priced = _priced(["CARREFOUR", "PAIN 1,20", "MERCI"])
    folded = decoder_probabilities(_one_hot(["store", "item", "noise"]), priced)
    assert folded.shape == (len(priced), DECODER_CLASSES)
    assert len(priced) == 1
    assert folded[0, ITEM] == 1.0


def test_chaque_role_tombe_sur_sa_classe():
    priced = _priced(["PAIN 1,20", "REMISE -0,20", "TOTAL 1,00", "CB 1,00"])
    folded = decoder_probabilities(
        _one_hot(["item", "discount", "total", "payment"]), priced
    )
    assert [int(row.argmax()) for row in folded] == [ITEM, DISCOUNT, TOTAL, PAYMENT]


def test_sous_total_et_total_sont_la_meme_reference():
    """Le décodeur ne distingue pas les deux : il les départage par le rang
    éligible, pas par le nom du rôle."""
    priced = _priced(["SOUS TOTAL 1,20", "TOTAL 1,20"])
    folded = decoder_probabilities(_one_hot(["subtotal", "total"]), priced)
    assert folded[0, TOTAL] == 1.0
    assert folded[1, TOTAL] == 1.0


def test_les_roles_non_contributifs_sont_ignores():
    """Les six rôles qu'aucun consommateur ne distingue sont déjà fondus en
    `noise` avant le tagger ; restent l'enseigne, la date et le libellé, que
    le décodeur ne doit jamais compter dans une somme."""
    priced = _priced(["TVA 20% 0,20", "CAISSE 5,00", "ARTICLES 3,00"])
    folded = decoder_probabilities(_one_hot(["noise", "store", "item_label"]), priced)
    assert [int(row.argmax()) for row in folded] == [IGNORE] * len(priced)


def test_la_probabilite_se_repartit_sans_se_perdre():
    """Replier, c'est sommer : aucune masse ne doit disparaître en route."""
    priced = _priced(["PAIN 1,20"])
    mixed = np.zeros((1, len(TAGGER_ROLES)))
    mixed[0, ROLE_COLUMN["item"]] = 0.5
    mixed[0, ROLE_COLUMN["total"]] = 0.3
    mixed[0, ROLE_COLUMN["subtotal"]] = 0.1
    mixed[0, ROLE_COLUMN["noise"]] = 0.1
    folded = decoder_probabilities(mixed, priced)
    assert folded[0, ITEM] == 0.5
    assert abs(folded[0, TOTAL] - 0.4) < 1e-12
    assert abs(folded.sum() - 1.0) < 1e-12
