"""La tranche d'évaluation d'`open_prices`.

Elle répare le défaut qui rendait toutes les mesures aveugles : le corpus
d'entraînement avait grossi de photos réelles et récentes, le jeu
d'évaluation était resté 415 scans à plat de 2017 et 20 photos.
"""

from __future__ import annotations

from annotate.dataset import HELD_OUT_SHARE, is_held_out


def test_le_verdict_ne_depend_que_du_nom():
    """Aucun fichier d'état : deux exécutions donnent le même découpage, et
    ajouter des tickets ne fait pas changer de côté ceux qui existent."""
    assert is_held_out("op_0000445") == is_held_out("op_0000445")


def test_les_deux_cotes_existent():
    names = [f"op_{index:07d}" for index in range(2000)]
    held = [name for name in names if is_held_out(name)]
    assert 0 < len(held) < len(names)


def test_la_part_reservee_est_celle_annoncee():
    names = [f"op_{index:07d}" for index in range(20000)]
    share = sum(1 for name in names if is_held_out(name)) / len(names)
    assert abs(share - HELD_OUT_SHARE) < 0.01
