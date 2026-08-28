"""Les lignes physiques qui recouvrent deux lignes imprimées.

Porter deux montants ne suffit pas à les distinguer : « 2 x 0,85 = 1,70 » et
une table de TVA en portent plusieurs sur une seule ligne imprimée. Ce qui les
sépare est la géométrie — deux lignes imprimées collées laissent leurs mots sur
deux lignes de base parallèles, et les résidus à la droite ajustée se
séparent en deux groupes.
"""
from __future__ import annotations

import json
from collections import Counter

from annotate.dataset import load
from bench.device_flow import load_tickets
from paths import RESULTS_DIR
from reference.local_flow import clustered_lines
from reference.structure import LAX_PRICE_PATTERN, merge_price_fragments

# En deçà, l'écart entre les deux groupes de résidus s'explique par le bruit
# des boîtes ; au-delà, il vaut une hauteur de mot, donc une ligne imprimée.
SPLIT_GAP_RATIO = 0.6


def _baseline_residuals(words) -> list[float]:
    """Écart vertical de chaque mot à la droite ajustée sur la ligne."""
    xs = [(w.left + w.right) / 2 for w in words]
    ys = [(w.top + w.bottom) / 2 for w in words]
    n = len(words)
    mean_x = sum(xs) / n
    mean_y = sum(ys) / n
    variance = sum((x - mean_x) ** 2 for x in xs)
    slope = (
        0.0
        if variance == 0
        else sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys)) / variance
    )
    return [y - (mean_y + slope * (x - mean_x)) for x, y in zip(xs, ys)]


def _median_height(words) -> float:
    heights = sorted(w.bottom - w.top for w in words)
    return heights[len(heights) // 2]


def splits(line) -> int:
    """Le nombre de lignes imprimées que ce cluster recouvre."""
    if len(line.words) < 2:
        return 1
    residuals = sorted(_baseline_residuals(line.words))
    gap = SPLIT_GAP_RATIO * _median_height(line.words)
    groups = 1
    for previous, current in zip(residuals, residuals[1:]):
        if current - previous > gap:
            groups += 1
    return groups


def amounts_on(line) -> int:
    return sum(len(LAX_PRICE_PATTERN.findall(word.text)) for word in line.words)


def survey(name: str, receipts) -> None:
    tickets = affected = lines_total = lines_split = costly = 0
    histogram: Counter[int] = Counter()
    for lines in receipts:
        if not lines:
            continue
        tickets += 1
        merged = [merge_price_fragments(line) for line in lines]
        touched = False
        for line in merged:
            lines_total += 1
            groups = splits(line)
            if groups == 1:
                continue
            lines_split += 1
            histogram[groups] += 1
            touched = True
            # Le cas qui coûte un article : la ligne fusionnée porte au moins
            # autant de montants que de lignes imprimées, donc l'un d'eux est
            # perdu par la lecture d'un seul prix.
            if amounts_on(line) >= groups:
                costly += 1
        affected += int(touched)
    print(f"\n=== {name} : {tickets} tickets, {lines_total} lignes")
    print(f"  lignes recouvrant plusieurs lignes imprimées : {lines_split} ({lines_split / lines_total:.2%})")
    print(f"  tickets touchés : {affected} ({affected / tickets:.1%})")
    print(f"  dont un montant est perdu : {costly}")
    print(f"  répartition : {dict(sorted(histogram.items()))}")


survey(
    "photos réelles (tranche d'évaluation)",
    (r.lines for r in load(held_out=True)),
)
survey(
    "FindIt (scans à plat)",
    (
        clustered_lines(json.loads(t.dump_path.read_text()))
        for t in load_tickets(RESULTS_DIR / "device_flow")
    ),
)
