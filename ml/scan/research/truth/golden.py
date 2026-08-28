"""Santé du golden, et arbitrage quand il ne tient pas debout.

Le golden a été annoté depuis l'image par un modèle : il se trompe, et il se
trompe en silence. Mesuré sur T1-test, **27 tickets sur 500 (5,4 %) ont un
golden dont la somme des articles ne fait pas son propre total** — la même
égalité que le pipeline s'impose. Ces tickets ne peuvent juger personne : une
lecture juste y est comptée fausse, et c'est ainsi que quatre tickets où le
pipeline avait raison sur une remise étaient portés à son passif.

Le remède ne consiste pas à faire confiance à une chaîne plutôt qu'à une
autre, mais à ne retenir que celles qui bouclent : la transcription officielle
FindIt (texte parfait, chaîne indépendante) et le corpus annoté (le même
ticket relu depuis l'image). Un ticket qu'aucune des trois ne fait boucler
sort du score — compté à part, jamais caché : c'est une vérité manquante, pas
une réussite.
"""

from __future__ import annotations

from enum import Enum

# La tolérance du checksum produit : le golden se juge à la même barre.
BALANCE_EPSILON = 0.005


class Verdict(str, Enum):
    GOLDEN = "golden cohérent"
    REPAIRED = "réparé par une chaîne indépendante"
    INCONCLUSIVE = "aucune chaîne ne boucle"


def net_total(receipt: dict) -> float:
    return round(
        sum(
            float(item["amount"]) - float(item.get("discount") or 0)
            for item in receipt["items"]
        ),
        2,
    )


def balances(receipt: dict | None) -> bool:
    """La somme des articles fait-elle le total imprimé ?"""
    if receipt is None or not receipt.get("items"):
        return False
    total = receipt.get("total")
    if total is None:
        return False
    return abs(net_total(receipt) - float(total)) < BALANCE_EPSILON


def best_reference(
    golden: dict, alternatives: list[dict | None]
) -> tuple[dict | None, Verdict]:
    """La lecture qui fait référence pour ce ticket, et d'où elle vient.

    Les chaînes concurrentes ne sont consultées que si le golden ne boucle
    pas, et dans l'ordre donné : la première qui boucle l'emporte."""
    if balances(golden):
        return golden, Verdict.GOLDEN
    for alternative in alternatives:
        if balances(alternative):
            return alternative, Verdict.REPAIRED
    return None, Verdict.INCONCLUSIVE
