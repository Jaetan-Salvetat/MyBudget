"""Santé du golden et arbitrage entre les chaînes de vérité."""

from __future__ import annotations

from truth.golden import Verdict, balances, best_reference


def receipt(items, total):
    return {
        "store": "CARREFOUR",
        "date": "2017-02-24",
        "total": total,
        "items": [
            {"name": name, "amount": amount, "discount": discount}
            for name, amount, discount in items
        ],
    }


PAIN = ("PAIN", 2.50, 0.0)
LAIT = ("LAIT", 1.00, 0.0)


def test_un_recu_dont_la_somme_fait_le_total_tient_debout() -> None:
    assert balances(receipt([PAIN, LAIT], 3.50))


def test_une_remise_entre_dans_la_somme() -> None:
    assert balances(receipt([("PAIN", 2.50, 0.50), LAIT], 3.00))


def test_une_somme_qui_ne_fait_pas_le_total_ne_tient_pas() -> None:
    assert not balances(receipt([PAIN, LAIT], 9.99))


def test_un_recu_sans_total_ne_tient_pas() -> None:
    assert not balances(receipt([PAIN], None))


def test_un_recu_sans_article_ne_tient_pas() -> None:
    assert not balances(receipt([], 3.50))


def test_un_golden_qui_tient_debout_reste_la_reference() -> None:
    """Aucune chaîne concurrente n'est consultée : le golden fait foi."""
    golden = receipt([PAIN, LAIT], 3.50)
    other = receipt([PAIN], 2.50)
    assert best_reference(golden, [other]) == (golden, Verdict.GOLDEN)


def test_la_premiere_chaine_qui_boucle_remplace_un_golden_bancal() -> None:
    golden = receipt([PAIN, LAIT], 9.99)
    bancal = receipt([PAIN], 9.99)
    juste = receipt([PAIN, LAIT], 3.50)
    assert best_reference(golden, [bancal, juste]) == (juste, Verdict.REPAIRED)


def test_sans_chaine_qui_boucle_personne_ne_tranche() -> None:
    golden = receipt([PAIN, LAIT], 9.99)
    assert best_reference(golden, [receipt([PAIN], 9.99)]) == (None, Verdict.INCONCLUSIVE)


def test_une_chaine_absente_ne_bloque_pas_l_arbitrage() -> None:
    golden = receipt([PAIN, LAIT], 9.99)
    juste = receipt([PAIN, LAIT], 3.50)
    assert best_reference(golden, [None, juste]) == (juste, Verdict.REPAIRED)
