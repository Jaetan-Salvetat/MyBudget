"""Décodage sous contrainte checksum : le checksum devient un guide.

Le classifieur de lignes sort des probabilités par rôle ; au lieu de prendre
l'argmax et de laisser le checksum dire oui/non, on cherche l'étiquetage le
plus probable dont la somme (articles − remises) retombe exactement sur une
référence imprimée. Subset-sum exact en centimes par programmation
dynamique. Les montants restent recopiés de l'OCR : le décodeur choisit,
il n'écrit jamais.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np

from line_features import PricedLine
from lines import PhysicalLine
from structure import ExtractedReceipt
from structure_ml import (
    DISCOUNT,
    IGNORE,
    ITEM,
    PAYMENT,
    TOTAL,
    load_classifier,
    receipt_from_labels,
)

CENTS_CAP = 500_000
NEGATIVE_CAP = 50_000
DEFAULT_MIN_PROB = 0.02
DEFAULT_MAX_REFERENCES = 3
DEFAULT_MIN_REFERENCE_PROB = 0.5
NEG_INF = -math.inf
LABEL_ORDER = (ITEM, DISCOUNT, IGNORE)


@dataclass(frozen=True)
class LineOptions:
    cents: int
    log_probs: dict[int, float]


def _contribution(label: int, cents: int) -> int:
    if label == ITEM:
        return cents
    if label == DISCOUNT:
        return -abs(cents)
    return 0


def best_assignment(
    lines: list[LineOptions],
    target_cents: int,
    min_prob: float = 0.0,
) -> list[int] | None:
    """Étiquetage maximisant Σ log P sous contrainte Σ contributions =
    target_cents. Une étiquette dont la probabilité est sous `min_prob` est
    interdite : on ne force jamais un rôle que le modèle juge impossible."""
    if not lines:
        return [] if target_cents == 0 else None
    floor = math.log(min_prob) if min_prob > 0 else NEG_INF
    positive_reach = min(sum(max(line.cents, 0) for line in lines), CENTS_CAP)
    negative_reach = min(sum(abs(line.cents) for line in lines), NEGATIVE_CAP)
    size = positive_reach + negative_reach + 1
    offset = negative_reach
    scores = np.full(size, NEG_INF)
    scores[offset] = 0.0
    choices = np.full((len(lines), size), -1, dtype=np.int8)

    for index, line in enumerate(lines):
        next_scores = np.full(size, NEG_INF)
        for label in LABEL_ORDER:
            log_prob = line.log_probs.get(label)
            if log_prob is None or log_prob < floor:
                continue
            shift = _contribution(label, line.cents)
            candidate = np.full(size, NEG_INF)
            if shift >= 0:
                candidate[shift:] = scores[: size - shift] + log_prob
            else:
                candidate[:shift] = scores[-shift:] + log_prob
            better = candidate > next_scores
            next_scores[better] = candidate[better]
            choices[index][better] = label
        scores = next_scores

    position = target_cents + offset
    if position < 0 or position >= size or scores[position] == NEG_INF:
        return None
    labels: list[int] = []
    for index in range(len(lines) - 1, -1, -1):
        label = int(choices[index][position])
        labels.append(label)
        position -= _contribution(label, lines[index].cents)
    labels.reverse()
    return labels


def _to_cents(price: float) -> int:
    return round(price * 100)


@dataclass(frozen=True)
class Hypothesis:
    reference_rank: int
    reference_role: int
    labels: list[int]
    log_prob: float


FORCED_IGNORE = LineOptions(cents=0, log_probs={IGNORE: 0.0})


def _line_options(
    lines: list[PricedLine],
    probas: np.ndarray,
    reference_rank: int,
    argmax_only: bool = False,
) -> list[LineOptions]:
    """Options par ligne sous deux invariants de ticket : rien ne compte
    après la ligne de référence (total ou paiement — la monnaie rendue qui
    suit un paiement en espèces n'est jamais un article), et un prix négatif
    n'est jamais un article. Une ligne à 0 centime n'apporte aucune
    information de somme."""
    options = []
    for rank, (priced, row) in enumerate(zip(lines, probas)):
        if rank == reference_rank:
            continue
        cents = _to_cents(priced.price)
        if cents == 0 or rank > reference_rank:
            options.append(FORCED_IGNORE)
            continue
        skip = max(row[IGNORE], row[TOTAL], row[PAYMENT])
        log_probs = {
            DISCOUNT: math.log(max(row[DISCOUNT], 1e-12)),
            IGNORE: math.log(max(skip, 1e-12)),
        }
        if cents > 0:
            log_probs[ITEM] = math.log(max(row[ITEM], 1e-12))
        if argmax_only:
            best_label = max(
                (label for label in LABEL_ORDER if label in log_probs),
                key=log_probs.get,
            )
            log_probs = {best_label: log_probs[best_label]}
        options.append(LineOptions(cents=cents, log_probs=log_probs))
    return options


def _reference_candidates(
    probas: np.ndarray, role: int, max_references: int, min_reference_prob: float
) -> list[int]:
    ranks = [
        int(rank)
        for rank in np.argsort(-probas[:, role], kind="stable")
        if probas[rank, role] >= min_reference_prob
    ]
    return ranks[:max_references]


def _assignment_log_prob(labels: list[int], options: list[LineOptions]) -> float:
    return sum(option.log_probs[label] for label, option in zip(labels, options))


def _best_hypothesis(
    lines: list[PricedLine],
    probas: np.ndarray,
    role: int,
    min_prob: float,
    max_references: int,
    min_reference_prob: float,
    argmax_only: bool,
) -> Hypothesis | None:
    best: Hypothesis | None = None
    for rank in _reference_candidates(probas, role, max_references, min_reference_prob):
        target = _to_cents(lines[rank].price)
        if target <= 0:
            continue
        options = _line_options(lines, probas, rank, argmax_only=argmax_only)
        labels = best_assignment(options, target, min_prob=min_prob)
        if labels is None:
            continue
        log_prob = _assignment_log_prob(labels, options) + math.log(
            max(probas[rank, role], 1e-12)
        )
        if best is None or log_prob > best.log_prob:
            full_labels = list(labels)
            full_labels.insert(rank, role)
            best = Hypothesis(rank, role, full_labels, log_prob)
    return best


def decode(
    lines: list[PricedLine],
    probas: np.ndarray,
    min_prob: float = DEFAULT_MIN_PROB,
    max_references: int = DEFAULT_MAX_REFERENCES,
    min_reference_prob: float = DEFAULT_MIN_REFERENCE_PROB,
) -> Hypothesis | None:
    """Les totaux d'abord, avec exploration. Un paiement ne sert de
    référence qu'en dernier recours et sans aucun flip : les articles tels
    que le modèle les voit doivent tomber pile sur le montant payé — deux
    signaux indépendants contre un total lu qui ne colle pas."""
    total = _best_hypothesis(
        lines, probas, TOTAL, min_prob, max_references, min_reference_prob, False
    )
    if total is not None:
        return total
    return _best_hypothesis(
        lines, probas, PAYMENT, min_prob, max_references, min_reference_prob, True
    )


def extract_constrained(
    merged: list[PhysicalLine], **decode_params
) -> ExtractedReceipt | None:
    model, featurize = load_classifier()
    lines, rows = featurize(merged)
    if not lines:
        return None
    probas = model.predict_proba(np.array(rows))
    hypothesis = decode(lines, probas, **decode_params)
    if hypothesis is None:
        return None
    return receipt_from_labels(merged, lines, hypothesis.labels)
