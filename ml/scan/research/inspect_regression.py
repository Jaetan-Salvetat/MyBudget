"""Les deux tickets que la séparation fait régresser : qu'a-t-elle coupé ?"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import reference.lines as L
from bench.photos_raw import raw_dumps
from reference.local_flow import clustered_lines

name = sys.argv[1]
path = raw_dumps()[Path(name).stem]
dump = json.loads(path.read_text())

original = L.split_baselines
L.split_baselines = lambda words: [words]
before = clustered_lines(dump)
L.split_baselines = original
after = clustered_lines(dump)

texts_before = [line.text for line in before]
texts_after = [line.text for line in after]
print(f"{name} : {len(before)} lignes -> {len(after)}")
for line in before:
    pieces = [
        " ".join(w.text for w in sorted(group, key=lambda w: w.left))
        for group in original(line.words)
    ]
    if len(pieces) > 1:
        print(f"\n  COUPÉ : {line.text!r}")
        for piece in pieces:
            print(f"      -> {piece!r}")
