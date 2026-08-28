"""Meme sonde, decoupee par origine de l'entite : un backbone monolingue FR
perd-il specifiquement sur les marques anglophones ?"""
import json, random, sys
from collections import defaultdict

import numpy as np
import torch
from sklearn.linear_model import LogisticRegression
from transformers import AutoModel, AutoTokenizer

from paths import ENTITIES_PATH

CAP, MAX_LENGTH, BATCH = 400, 32, 128
ANGLO = {"Q30", "us", "Q145", "gb", "ca", "au", "Q16", "Q408", "ie", "nz"}
FRANCO = {"Q142", "fr", "be", "ch", "Q31", "Q39"}


def origin(countries: list[str]) -> str:
    tags = set(countries or [])
    if tags & FRANCO:
        return "francophone"
    if tags & ANGLO:
        return "anglophone"
    return "autre / international"


by_slug = defaultdict(list)
for line in ENTITIES_PATH.read_text().splitlines():
    e = json.loads(line)
    by_slug[e["slug"]].append((e["name"], origin(e.get("countries"))))

rng = random.Random(42)
train, test = [], []
slugs = sorted(by_slug)
for index, slug in enumerate(slugs):
    rows = sorted(set(by_slug[slug]))
    rng.shuffle(rows)
    rows = rows[:CAP]
    if len(rows) < 8:
        continue
    cut = int(len(rows) * 0.8)
    train += [(n, o, index) for n, o in rows[:cut]]
    test += [(n, o, index) for n, o in rows[cut:]]

counts = defaultdict(int)
for _, o, _ in test:
    counts[o] += 1
print(f"{len(train)} train / {len(test)} test — {dict(counts)}\n", flush=True)


def embed(repo, names):
    tok = AutoTokenizer.from_pretrained(repo)
    model = AutoModel.from_pretrained(repo, dtype=torch.float32).eval()
    out = []
    for start in range(0, len(names), BATCH):
        enc = tok(names[start:start + BATCH], return_tensors="pt", padding=True,
                  truncation=True, max_length=MAX_LENGTH)
        with torch.no_grad():
            hidden = model(**enc).last_hidden_state
        mask = enc["attention_mask"].unsqueeze(-1).float()
        pooled = (hidden * mask).sum(1) / mask.sum(1).clamp(min=1e-9)
        out.append(torch.nn.functional.normalize(pooled, dim=-1).numpy())
    return np.concatenate(out)


for repo in sys.argv[1:]:
    train_x = embed(repo, [n for n, _, _ in train])
    test_x = embed(repo, [n for n, _, _ in test])
    probe = LogisticRegression(max_iter=2000, C=10.0).fit(train_x, [y for _, _, y in train])
    predicted = probe.predict(test_x)
    print(f"{repo}", flush=True)
    for label in ("anglophone", "francophone", "autre / international"):
        rows = [i for i, (_, o, _) in enumerate(test) if o == label]
        if not rows:
            continue
        ok = sum(predicted[i] == test[i][2] for i in rows)
        print(f"  {label:24s} {ok / len(rows):5.1%}  ({ok}/{len(rows)})", flush=True)
