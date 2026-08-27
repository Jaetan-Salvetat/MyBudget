"""Ce que vaudrait une extraction décidée par le tagger de rôles.

Trois lectures du même corpus annoté, comparées au checksum :

- la **chaîne actuelle** — le tagger de rôles, puis le décodeur ;
- les **rôles annotés** — le plafond : ce que le corpus dit être la vérité ;
- les **rôles prédits** — ce que le tagger rend aujourd'hui.

L'écart plafond ↔ prédit est la seule chose à faire baisser : le lecteur est
le même dans les deux cas, donc tout ce qui les sépare vient du modèle.

Le second tableau dit *pourquoi* l'écart existe. Le tagger est évalué par
ligne, la métrique produit se juge par ticket, et une erreur suffit à perdre
le ticket. La colonne qui compte n'est donc pas l'exactitude par ligne mais
la part de tickets **sans aucune erreur sur un rôle qui touche aux montants**.

    uv run python -m bench.roles
"""

from __future__ import annotations

import collections
import sys

from annotate.dataset import load
from annotate.schema import DISCOUNT, ITEM, SUBTOTAL, TOTAL
from reference.decode_roles import extract_role_constrained
from reference.header_ml import predicted_roles, role_probabilities
from reference.line_labels import tagger_role
from reference.structure import merge_price_fragments
from reference.structure_roles import extract_roles

HELD_OUT_CORPORA = ("T1-test", "photos_pixel")
CONTRIBUTING = (ITEM, DISCOUNT, TOTAL, SUBTOTAL)
MAX_REPORTED_ERRORS = 5
TOP_CONFUSIONS = 6


def _chain_balances(lines, merged) -> bool:
    """Ce que le flow prouve sur cette seule lecture : tagger puis décodeur."""
    receipt = extract_role_constrained(
        merged, role_probas=role_probabilities(lines)
    )
    return receipt is not None and receipt.checksum_ok


def _balances(merged, roles) -> bool:
    receipt = extract_roles(merged, roles)
    return receipt is not None and receipt.checksum_ok


def report(corpus: str) -> None:
    receipts = [record for record in load(held_out=True) if record.corpus == corpus]
    if not receipts:
        print(f"=== {corpus} : aucun ticket")
        return

    counts: collections.Counter[str] = collections.Counter()
    confusions: collections.Counter[str] = collections.Counter()
    errors_per_receipt: collections.Counter[int] = collections.Counter()
    lines_total = lines_right = 0

    for record in receipts:
        merged = [merge_price_fragments(line) for line in record.lines]
        predicted = predicted_roles(record.lines)
        # Le tagger ne prédit pas les six rôles que personne ne lit : la
        # vérité se compare dans son vocabulaire, pas dans celui du corpus.
        annotated = [tagger_role(role) for role in record.roles]

        counts["chaîne actuelle"] += _chain_balances(record.lines, merged)
        counts["rôles annotés (plafond)"] += _balances(merged, annotated)
        counts["rôles prédits"] += _balances(merged, predicted)

        wrong = wrong_on_amounts = 0
        for index in range(min(len(predicted), len(annotated))):
            lines_total += 1
            expected = annotated[index]
            if predicted[index] == expected:
                lines_right += 1
                continue
            wrong += 1
            confusions[f"{expected} → {predicted[index]}"] += 1
            if expected in CONTRIBUTING or predicted[index] in CONTRIBUTING:
                wrong_on_amounts += 1
        errors_per_receipt[min(wrong, MAX_REPORTED_ERRORS)] += 1
        counts["tickets sans erreur de rôle"] += wrong == 0
        counts["tickets sans erreur sur les montants"] += wrong_on_amounts == 0

    total = len(receipts)
    print(f"=== {corpus} : {total} tickets, {lines_total} lignes")
    print("  checksum")
    for key in ("chaîne actuelle", "rôles annotés (plafond)", "rôles prédits"):
        print(f"    {key:<26} {counts[key]:>4} ({counts[key] / total:.1%})")
    print("  tagger de rôles")
    print(f"    {'exactitude par ligne':<26} {lines_right / lines_total:.1%}")
    for key in ("tickets sans erreur de rôle", "tickets sans erreur sur les montants"):
        print(f"    {key:<26} {counts[key]:>4} ({counts[key] / total:.1%})")
    spread = ", ".join(
        f"{errors}: {count}" for errors, count in sorted(errors_per_receipt.items())
    )
    print(f"    erreurs par ticket         {{{spread}}}")
    print("  confusions les plus fréquentes")
    for confusion, count in confusions.most_common(TOP_CONFUSIONS):
        print(f"    {confusion:<26} {count:>4}")
    print()


def main(argv: list[str]) -> int:
    for corpus in argv or HELD_OUT_CORPORA:
        report(corpus)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
