"""Fusion de deux passes OCR sur la même image, ligne physique à ligne.

Les deux passes (brute, prétraitée) abîment des lignes différentes : l'une
colle une lettre au prix, l'autre saute un article. Alignées par position
verticale, elles se complètent : une ligne non chiffrée dans la passe
principale prend la lecture de l'autre, une ligne absente est insérée, un
montant différent devient une alternative que le décodeur sous contrainte
arbitre. Rien n'est inventé : chaque montant vient d'une passe OCR.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from reference.lines import PhysicalLine
from reference.structure import _rightmost_price, parse_price

ALIGNMENT_TOLERANCE_RATIO = 0.6


@dataclass(frozen=True)
class FusedPass:
    lines: list[PhysicalLine]
    alternatives: dict[int, int] = field(default_factory=dict)


@dataclass(frozen=True)
class _Placed:
    line: PhysicalLine
    center_y: float
    alternative_cents: int | None = None


def _center_y(line: PhysicalLine) -> float:
    centers = sorted(word.center_y for word in line.words)
    return centers[len(centers) // 2]


def _median_height(lines: list[PhysicalLine]) -> float:
    heights = sorted(word.height for line in lines for word in line.words)
    return heights[len(heights) // 2] if heights else 1.0


def _cents(line: PhysicalLine) -> int | None:
    priced = _rightmost_price(line)
    return None if priced is None else round(priced[0] * 100)


def _price_count(line: PhysicalLine) -> int:
    return sum(parse_price(word.text) is not None for word in line.words)


def _match_secondary(
    primary: list[PhysicalLine], secondary: list[PhysicalLine], tolerance: float
) -> tuple[dict[int, list[int]], list[int]]:
    matches: dict[int, list[int]] = {index: [] for index in range(len(primary))}
    unmatched: list[int] = []
    centers = [_center_y(line) for line in primary]
    for secondary_index, line in enumerate(secondary):
        center = _center_y(line)
        nearest = min(
            range(len(primary)), key=lambda i: abs(centers[i] - center), default=None
        )
        if nearest is None or abs(centers[nearest] - center) > tolerance:
            unmatched.append(secondary_index)
        else:
            matches[nearest].append(secondary_index)
    return matches, unmatched


def _place_single(primary: PhysicalLine, match: PhysicalLine) -> list[_Placed]:
    primary_cents = _cents(primary)
    match_cents = _cents(match)
    if primary_cents is None and match_cents is not None:
        return [_Placed(match, _center_y(match))]
    alternative = (
        match_cents
        if primary_cents is not None
        and match_cents is not None
        and match_cents != primary_cents
        else None
    )
    return [_Placed(primary, _center_y(primary), alternative)]


def _place_several(primary: PhysicalLine, matches: list[PhysicalLine]) -> list[_Placed]:
    if _price_count(primary) >= 2:
        return [_Placed(match, _center_y(match)) for match in matches]
    primary_cents = _cents(primary)
    placed = [_Placed(primary, _center_y(primary))]
    placed.extend(
        _Placed(match, _center_y(match))
        for match in matches
        if _cents(match) not in (None, primary_cents)
    )
    return placed


def fuse_passes(
    primary: list[PhysicalLine], secondary: list[PhysicalLine]
) -> FusedPass:
    tolerance = ALIGNMENT_TOLERANCE_RATIO * _median_height(primary)
    matches, unmatched = _match_secondary(primary, secondary, tolerance)
    placed: list[_Placed] = []
    for index, line in enumerate(primary):
        matched = [secondary[i] for i in matches[index]]
        if not matched:
            placed.append(_Placed(line, _center_y(line)))
        elif len(matched) == 1:
            placed.extend(_place_single(line, matched[0]))
        else:
            placed.extend(_place_several(line, matched))
    placed.extend(_Placed(secondary[i], _center_y(secondary[i])) for i in unmatched)
    placed.sort(key=lambda entry: entry.center_y)
    return FusedPass(
        lines=[entry.line for entry in placed],
        alternatives={
            index: entry.alternative_cents
            for index, entry in enumerate(placed)
            if entry.alternative_cents is not None
        },
    )
