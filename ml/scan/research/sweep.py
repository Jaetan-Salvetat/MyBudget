"""Le seuil de séparation, choisi par la mesure et non à la main.

Deux corpus, deux métriques qui comptent : les tickets dont la somme est
prouvée, et les faux auto-validés — la barre étant zéro nouveau faux.
"""
from __future__ import annotations

import json
import sys

import reference.lines as L

ratio = float(sys.argv[1]) if len(sys.argv) > 1 else L.BASELINE_SPLIT_RATIO
L.BASELINE_SPLIT_RATIO = ratio
if ratio == 0:
    L.split_baselines = lambda words: [words]

from bench.device_flow import load_tickets  # noqa: E402
from bench.scoring import count_edits  # noqa: E402
from paths import RESULTS_DIR  # noqa: E402
from reference.local_flow import VERIFIED_SOURCES, decide_local  # noqa: E402

proved = wrong = total = 0
for ticket in load_tickets(RESULTS_DIR / "device_flow"):
    dump = json.loads(ticket.dump_path.read_text())
    outcome = decide_local(dump)
    total += 1
    if outcome.source not in VERIFIED_SOURCES:
        continue
    proved += 1
    expected = [round(float(i["amount"]), 2) for i in ticket.golden["receipt"]["items"]]
    if count_edits(outcome.amounts, expected):
        wrong += 1
label = "désactivée" if ratio == 0 else f"{ratio:g}"
print(f"séparation {label:>10} : prouvés {proved}/{total}, FAUX auto-validés {wrong}")
