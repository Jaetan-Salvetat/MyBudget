"""Décodage sous contrainte checksum : le checksum devient un guide.

Le classifieur de lignes sort des probabilités par rôle ; au lieu de prendre
l'argmax et de laisser le checksum dire oui/non, on cherche l'étiquetage le
plus probable dont la somme (articles − remises) retombe exactement sur une
référence. Subset-sum exact en centimes par programmation dynamique. Les
montants restent recopiés de l'OCR : le décodeur choisit, il n'écrit jamais.

Les références viennent de plusieurs sources indépendantes — lignes total
du classifieur, dernier total lexical, décomposition TVA, espèces − rendu —
fusionnées par montant : deux sources d'accord valent plus qu'une. Les
invariants structurels (`invariants.py`) ferment l'espace de recherche.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np

from invariants import (
    PAYMENT_CHANGE,
    TAX,
    TOTAL_LINE,
    Constraints,
    constraints,
)
from line_features import PricedLine
from lines import PhysicalLine
from structure import ExtractedReceipt, _printed_count
from structure_ml import (
    DISCOUNT,
    IGNORE,
    ITEM,
    PAYMENT,
    TOTAL,
    load_classifier,
    receipt_from_labels,
    single_item_receipt,
)

CENTS_CAP = 500_000
NEGATIVE_CAP = 50_000
DEFAULT_MIN_PROB = 0.02
DEFAULT_MAX_REFERENCES = 4
DEFAULT_MIN_REFERENCE_PROB = 0.5
NEG_INF = -math.inf
LABEL_ORDER = (ITEM, DISCOUNT, IGNORE)
CLASSIFIER = "classifier"
ARITHMETIC_SOURCES = (TAX, PAYMENT_CHANGE)
EVIDENCE_PROB = 0.5
TOTAL_LINE_PROB_FLOOR = 0.1
CONCORDANCE_BONUS = 1.5
SINGLE_ITEM_MIN_SOURCES = 2
SINGLE_ITEM_COUNTS = (None, 1)


ALTERNATIVE_PROB = 0.5
VARIANT_COUNT = 2
SOFT_IGNORE_PROB = 0.5


@dataclass(frozen=True)
class LineOptions:
    cents: int
    log_probs: dict[int, float]
    alternative_cents: int | None = None

    def variants(self) -> list[tuple[int, int, float]]:
        """(variante, centimes, pénalité) : la lecture principale, puis la
        lecture alternative de l'autre passe OCR quand elle diffère."""
        variants = [(0, self.cents, 0.0)]
        if self.alternative_cents is not None:
            variants.append((1, self.alternative_cents, math.log(ALTERNATIVE_PROB)))
        return variants


@dataclass(frozen=True)
class Reference:
    cents: int
    cutoff_rank: int
    role: int
    log_prob: float
    sources: tuple[str, ...]
    line_rank: int | None


@dataclass(frozen=True)
class Assignment:
    labels: list[int]
    cents: list[int]


@dataclass(frozen=True)
class Hypothesis:
    reference_cents: int
    reference_role: int
    labels: list[int]
    log_prob: float
    sources: tuple[str, ...] = ()
    single_item: bool = False
    cents: list[int] = field(default_factory=list)


FORCED_IGNORE = LineOptions(cents=0, log_probs={IGNORE: 0.0})


def _discount_capacity(lines: list[LineOptions], floor: float) -> int:
    """Somme des remises possibles : borne la plage utile des sommes
    intermédiaires à [−D, cible + D] — un état au-delà ne peut plus retomber
    sur la cible, l'élaguer ne change pas l'optimum."""
    capacity = 0
    for line in lines:
        log_prob = line.log_probs.get(DISCOUNT)
        if log_prob is not None and log_prob >= floor:
            capacity += max(abs(cents) for _, cents, _ in line.variants())
    return capacity


def _contribution(label: int, cents: int) -> int:
    if label == ITEM:
        return cents
    if label == DISCOUNT:
        return -abs(cents)
    return 0


def _encode(label: int, variant: int) -> int:
    return label * VARIANT_COUNT + variant


def _decode_choice(choice: int) -> tuple[int, int]:
    return divmod(int(choice), VARIANT_COUNT)


def best_assignment_detail(
    lines: list[LineOptions],
    target_cents: int,
    min_prob: float = 0.0,
) -> Assignment | None:
    """Étiquetage maximisant Σ log P sous contrainte Σ contributions =
    target_cents, avec pour chaque ligne le montant retenu (lecture
    principale ou alternative). Une étiquette dont la probabilité est sous
    `min_prob` est interdite : on ne force jamais un rôle que le modèle
    juge impossible."""
    if not lines:
        return Assignment([], []) if target_cents == 0 else None
    if target_cents < 0 or target_cents > CENTS_CAP:
        return None
    floor = math.log(min_prob) if min_prob > 0 else NEG_INF
    discount_capacity = min(_discount_capacity(lines, floor), NEGATIVE_CAP)
    size = target_cents + 2 * discount_capacity + 1
    offset = discount_capacity
    scores = np.full(size, NEG_INF)
    scores[offset] = 0.0
    choices = np.full((len(lines), size), -1, dtype=np.int8)

    for index, line in enumerate(lines):
        next_scores = np.full(size, NEG_INF)
        for label in LABEL_ORDER:
            log_prob = line.log_probs.get(label)
            if log_prob is None or log_prob < floor:
                continue
            for variant, cents, penalty in line.variants():
                shift = _contribution(label, cents)
                if abs(shift) >= size:
                    continue
                candidate = np.full(size, NEG_INF)
                if shift >= 0:
                    candidate[shift:] = scores[: size - shift] + log_prob + penalty
                else:
                    candidate[:shift] = scores[-shift:] + log_prob + penalty
                better = candidate > next_scores
                next_scores[better] = candidate[better]
                choices[index][better] = _encode(label, variant)
        scores = next_scores

    position = target_cents + offset
    if position < 0 or position >= size or scores[position] == NEG_INF:
        return None
    labels: list[int] = []
    amounts: list[int] = []
    for index in range(len(lines) - 1, -1, -1):
        label, variant = _decode_choice(choices[index][position])
        cents = lines[index].variants()[variant][1]
        labels.append(label)
        amounts.append(cents)
        position -= _contribution(label, cents)
    labels.reverse()
    amounts.reverse()
    return Assignment(labels, amounts)


def best_assignment(
    lines: list[LineOptions],
    target_cents: int,
    min_prob: float = 0.0,
) -> list[int] | None:
    assignment = best_assignment_detail(lines, target_cents, min_prob)
    return None if assignment is None else assignment.labels


def _to_cents(price: float) -> int:
    return round(price * 100)


def _line_options(
    lines: list[PricedLine],
    probas: np.ndarray,
    cutoff_rank: int,
    forced_ignore: frozenset[int] = frozenset(),
    reference_rank: int | None = None,
    argmax_only: bool = False,
    alternatives: dict[int, int] | None = None,
    soft_ignore: frozenset[int] = frozenset(),
) -> list[LineOptions]:
    """Options par ligne sous les invariants de ticket : rien ne compte
    après la référence (la monnaie rendue qui suit un paiement en espèces
    n'est jamais un article), un prix négatif n'est jamais un article, une
    ligne à 0 centime n'apporte aucune information de somme, les lignes
    structurellement exclues (taxe, HT, récap de remises) sont ignorées et
    un total de rayon détecté par l'arithmétique peut toujours l'être."""
    options = []
    for rank, (priced, row) in enumerate(zip(lines, probas)):
        cents = _to_cents(priced.price)
        if (
            rank == reference_rank
            or rank in forced_ignore
            or cents == 0
            or rank > cutoff_rank
        ):
            options.append(FORCED_IGNORE)
            continue
        skip = max(row[IGNORE], row[TOTAL], row[PAYMENT])
        if rank in soft_ignore:
            skip = max(skip, SOFT_IGNORE_PROB)
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
        alternative = (alternatives or {}).get(rank)
        options.append(
            LineOptions(
                cents=cents,
                log_probs=log_probs,
                alternative_cents=alternative if alternative != cents else None,
            )
        )
    return options


def _classifier_references(
    lines: list[PricedLine],
    probas: np.ndarray,
    structure: Constraints,
    min_reference_prob: float,
) -> list[Reference]:
    return [
        Reference(
            cents=_to_cents(lines[rank].price),
            cutoff_rank=rank,
            role=TOTAL,
            log_prob=math.log(probas[rank, TOTAL]),
            sources=(CLASSIFIER,),
            line_rank=rank,
        )
        for rank in sorted(structure.reference_ranks)
        if probas[rank, TOTAL] >= min_reference_prob and lines[rank].price > 0
    ]


def _evidence_references(probas: np.ndarray, structure: Constraints) -> list[Reference]:
    references = []
    for evidence in structure.evidences:
        if evidence.source == TOTAL_LINE:
            prob = max(probas[evidence.line_rank, TOTAL], TOTAL_LINE_PROB_FLOOR)
        else:
            prob = EVIDENCE_PROB
        references.append(
            Reference(
                cents=evidence.cents,
                cutoff_rank=evidence.cutoff_rank,
                role=TOTAL,
                log_prob=math.log(prob),
                sources=(evidence.source,),
                line_rank=evidence.line_rank,
            )
        )
    return references


def merge_references(references: list[Reference]) -> list[Reference]:
    """Fusion par montant : la ligne imprimée fixe la coupure quand il y en a
    une, chaque source supplémentaire d'accord ajoute un bonus."""
    by_cents: dict[int, list[Reference]] = {}
    for reference in references:
        if reference.cents > 0:
            by_cents.setdefault(reference.cents, []).append(reference)
    merged = []
    for cents, group in by_cents.items():
        sources = tuple(dict.fromkeys(s for r in group for s in r.sources))
        printed = [r for r in group if r.line_rank is not None]
        anchor = printed[0] if printed else min(group, key=lambda r: r.cutoff_rank)
        merged.append(
            Reference(
                cents=cents,
                cutoff_rank=anchor.cutoff_rank,
                role=TOTAL,
                log_prob=max(r.log_prob for r in group)
                + (len(sources) - 1) * CONCORDANCE_BONUS,
                sources=sources,
                line_rank=anchor.line_rank,
            )
        )
    return sorted(merged, key=lambda r: -r.log_prob)


def _assignment_log_prob(labels: list[int], options: list[LineOptions]) -> float:
    return sum(option.log_probs[label] for label, option in zip(labels, options))


def _hypothesis(
    lines: list[PricedLine],
    probas: np.ndarray,
    reference: Reference,
    structure: Constraints,
    min_prob: float,
    argmax_only: bool = False,
    alternatives: dict[int, int] | None = None,
) -> Hypothesis | None:
    options = _line_options(
        lines,
        probas,
        reference.cutoff_rank,
        structure.forced_ignore,
        reference.line_rank,
        argmax_only=argmax_only,
        alternatives=alternatives,
        soft_ignore=structure.soft_ignore,
    )
    assignment = best_assignment_detail(options, reference.cents, min_prob=min_prob)
    if assignment is None:
        return None
    labels = assignment.labels
    log_prob = _assignment_log_prob(labels, options) + reference.log_prob
    if reference.line_rank is not None:
        labels[reference.line_rank] = reference.role
    return Hypothesis(
        reference_cents=reference.cents,
        reference_role=reference.role,
        labels=labels,
        log_prob=log_prob,
        sources=reference.sources,
        cents=assignment.cents,
    )


def _best_total_hypothesis(
    lines: list[PricedLine],
    probas: np.ndarray,
    references: list[Reference],
    structure: Constraints,
    min_prob: float,
    alternatives: dict[int, int] | None,
) -> Hypothesis | None:
    best: Hypothesis | None = None
    for reference in references:
        hypothesis = _hypothesis(
            lines, probas, reference, structure, min_prob, alternatives=alternatives
        )
        if hypothesis is not None and (
            best is None or hypothesis.log_prob > best.log_prob
        ):
            best = hypothesis
    return best


def _payment_hypothesis(
    lines: list[PricedLine],
    probas: np.ndarray,
    structure: Constraints,
    max_references: int,
    min_reference_prob: float,
) -> Hypothesis | None:
    """Un paiement ne sert de référence qu'en dernier recours et sans aucun
    flip : les articles tels que le modèle les voit doivent tomber pile sur
    le montant payé — deux signaux indépendants contre un total lu faux."""
    ranks = [
        int(rank)
        for rank in np.argsort(-probas[:, PAYMENT], kind="stable")
        if probas[rank, PAYMENT] >= min_reference_prob
        and rank not in structure.forced_ignore
        and lines[rank].price > 0
    ]
    best: Hypothesis | None = None
    for rank in ranks[:max_references]:
        reference = Reference(
            cents=_to_cents(lines[rank].price),
            cutoff_rank=rank,
            role=PAYMENT,
            log_prob=math.log(probas[rank, PAYMENT]),
            sources=(CLASSIFIER,),
            line_rank=rank,
        )
        hypothesis = _hypothesis(
            lines, probas, reference, structure, 0.0, argmax_only=True
        )
        if hypothesis is not None and (
            best is None or hypothesis.log_prob > best.log_prob
        ):
            best = hypothesis
    return best


def _no_item_candidate(options: list[LineOptions], min_prob: float) -> bool:
    floor = math.log(min_prob) if min_prob > 0 else NEG_INF
    return all(option.log_probs.get(ITEM, NEG_INF) < floor for option in options)


def _single_item_hypothesis(
    lines: list[PricedLine],
    probas: np.ndarray,
    references: list[Reference],
    structure: Constraints,
    min_prob: float,
    printed_count: int | None,
) -> Hypothesis | None:
    """Ticket sans aucune ligne d'article (parking, carburant) : un montant
    prouvé par l'arithmétique ET une seconde source, sans candidat article
    ni compteur d'articles contraire, est l'unique achat."""
    if printed_count not in SINGLE_ITEM_COUNTS:
        return None
    for reference in references:
        if len(reference.sources) < SINGLE_ITEM_MIN_SOURCES:
            continue
        if not any(source in ARITHMETIC_SOURCES for source in reference.sources):
            continue
        options = _line_options(
            lines,
            probas,
            reference.cutoff_rank,
            structure.forced_ignore,
            reference.line_rank,
            soft_ignore=structure.soft_ignore,
        )
        if not _no_item_candidate(options, min_prob):
            continue
        labels = [IGNORE] * len(lines)
        if reference.line_rank is not None:
            labels[reference.line_rank] = TOTAL
        return Hypothesis(
            reference_cents=reference.cents,
            reference_role=TOTAL,
            labels=labels,
            log_prob=reference.log_prob,
            sources=reference.sources,
            single_item=True,
        )
    return None


def references(
    lines: list[PricedLine],
    probas: np.ndarray,
    structure: Constraints,
    min_reference_prob: float = DEFAULT_MIN_REFERENCE_PROB,
) -> list[Reference]:
    return merge_references(
        _classifier_references(lines, probas, structure, min_reference_prob)
        + _evidence_references(probas, structure)
    )


def decode(
    lines: list[PricedLine],
    probas: np.ndarray,
    min_prob: float = DEFAULT_MIN_PROB,
    max_references: int = DEFAULT_MAX_REFERENCES,
    min_reference_prob: float = DEFAULT_MIN_REFERENCE_PROB,
    printed_count: int | None = None,
    alternatives: dict[int, int] | None = None,
) -> Hypothesis | None:
    structure = constraints(lines)
    candidates = references(lines, probas, structure, min_reference_prob)[
        :max_references
    ]
    total = _best_total_hypothesis(
        lines, probas, candidates, structure, min_prob, alternatives
    )
    if total is not None:
        return total
    payment = _payment_hypothesis(
        lines, probas, structure, max_references, min_reference_prob
    )
    if payment is not None:
        return payment
    return _single_item_hypothesis(
        lines, probas, candidates, structure, min_prob, printed_count
    )


def _rank_alternatives(
    lines: list[PricedLine], alternatives: dict[int, int] | None
) -> dict[int, int]:
    """Alternatives indexées par ligne fusionnée → par rang de ligne chiffrée."""
    if not alternatives:
        return {}
    return {
        rank: alternatives[priced.index]
        for rank, priced in enumerate(lines)
        if priced.index in alternatives
    }


def _with_chosen_amounts(
    lines: list[PricedLine], labels: list[int], cents: list[int]
) -> list[PricedLine]:
    """Réécrit le montant des seules lignes contributives dont le décodeur a
    retenu la lecture alternative."""
    return [
        PricedLine(priced.index, priced.line, chosen / 100, priced.word)
        if label in (ITEM, DISCOUNT) and chosen != _to_cents(priced.price)
        else priced
        for priced, label, chosen in zip(lines, labels, cents)
    ]


def extract_constrained(
    merged: list[PhysicalLine],
    alternatives: dict[int, int] | None = None,
    **decode_params,
) -> ExtractedReceipt | None:
    model, featurize = load_classifier()
    lines, rows = featurize(merged)
    if not lines:
        return None
    probas = model.predict_proba(np.array(rows))
    hypothesis = decode(
        lines,
        probas,
        printed_count=_printed_count(merged),
        alternatives=_rank_alternatives(lines, alternatives),
        **decode_params,
    )
    if hypothesis is None:
        return None
    reference_total = hypothesis.reference_cents / 100
    if hypothesis.single_item:
        return single_item_receipt(merged, reference_total)
    chosen = (
        _with_chosen_amounts(lines, hypothesis.labels, hypothesis.cents)
        if hypothesis.cents
        else lines
    )
    return receipt_from_labels(
        merged, chosen, hypothesis.labels, reference_total=reference_total
    )
