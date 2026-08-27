"""Le vocabulaire de score partagé par les benchs.

`count_edits` compte des montants — ce que le checksum protège. La métrique
produit, elle, est dans `bench/exactness.py` : un ticket n'est bon que si
l'enseigne, la date, le total et chaque libellé le sont aussi.
"""

from __future__ import annotations

from dataclasses import dataclass, field

AMOUNT_EPSILON = 0.005


@dataclass
class TicketRun:
    name: str
    stage: str
    edits: int
    double_validated: bool


@dataclass
class StageStats:
    tickets: int = 0
    edits_total: int = 0
    faulty: list[TicketRun] = field(default_factory=list)

    def add(self, run: TicketRun) -> None:
        self.tickets += 1
        self.edits_total += run.edits
        if run.edits:
            self.faulty.append(run)


def count_edits(got: list[tuple[float, float]], expected: list[float]) -> int:
    """Corrections utilisateur : articles attendus manqués + extraits en trop,
    à impact monétaire réel. Deux équivalences neutralisées (audit du run
    device) : un attendu à 0,00 € manqué ne coûte rien, et un attendu négatif
    est équivalent à une remise du même montant sur un article extrait."""
    remaining = list(expected)
    discounts = [d for _amount, d in got if d > 0]
    wrong = 0
    for amount, _discount in got:
        hit = next((p for p in remaining if abs(p - amount) < AMOUNT_EPSILON), None)
        if hit is not None:
            remaining.remove(hit)
        else:
            wrong += 1
    misses = 0
    for pending in remaining:
        if abs(pending) < AMOUNT_EPSILON:
            continue
        if pending < 0:
            refund = next(
                (d for d in discounts if abs(d + pending) < AMOUNT_EPSILON),
                None,
            )
            if refund is not None:
                discounts.remove(refund)
                continue
        misses += 1
    return wrong + misses
