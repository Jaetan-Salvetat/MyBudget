"""Le bench photos, avec et sans la séparation des lignes de base."""
from __future__ import annotations

import sys

import reference.lines as L

if "--off" in sys.argv:
    L.split_baselines = lambda words: [words]

from bench.photos_raw import report, run  # noqa: E402

print("séparation", "DÉSACTIVÉE" if "--off" in sys.argv else "active")
report(run(None))
