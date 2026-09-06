"""Qui gagne et qui perd, ticket par ticket — et sur combien de tickets la
séparation a seulement quelque chose à faire."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import reference.lines as L

_split = L.split_baselines
if "--off" in sys.argv:
    L.split_baselines = lambda words: [words]

from bench.photos_raw import run  # noqa: E402

rows = {r["name"]: r for r in run(None)}
out = "off" if "--off" in sys.argv else "on"
json.dump(rows, open(f"/tmp/ab_{out}.json", "w"))
print(out, len(rows))
