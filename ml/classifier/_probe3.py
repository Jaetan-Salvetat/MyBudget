"""La sonde precedente ne testait que le nom nu. Deux axes de plus, ceux qui
manquaient : l'origine de l'entite (francaise, anglophone, internationale) et
la langue de la phrase qui l'entoure — un utilisateur ecrit en langage
naturel, pas en noms propres isoles.

Memes entites, memes classes, seule la forme de surface change : le seul
facteur qui varie entre les trois colonnes est la langue du phrase.
"""
import json, random, sys
from collections import defaultdict

import numpy as np
import torch
from sklearn.linear_model import LogisticRegression
from transformers import AutoModel, AutoTokenizer

from corpus.quick_add.build import (
    EN_CONTEXTS, EN_EXPENSE_PREFIXES, EN_SUFFIXES, ENGLISH_WRAPPERS,
    FR_CONTEXTS, FR_EXPENSE_PREFIXES, FR_SUFFIXES, FRENCH_WRAPPERS,
)
from paths import ENTITIES_PATH

CAP, MAX_LENGTH, BATCH = 400, 32, 128
ANGLO = {"Q30", "us", "Q145", "gb", "ca", "au", "Q16", "Q408", "ie", "nz"}
FRANCO = {"Q142", "fr", "be", "ch", "Q31", "Q39"}


def origin(countries):
    tags = set(countries or [])
    if tags & FRANCO:
        return "entite francaise"
    if tags & ANGLO:
        return "entite anglophone"
    return "entite internationale"


def phrase(name, rng, *, french):
    prefixes = FR_EXPENSE_PREFIXES if french else EN_EXPENSE_PREFIXES
    suffixes = FR_SUFFIXES if french else EN_SUFFIXES
    contexts = FR_CONTEXTS if french else EN_CONTEXTS
    wrappers = FRENCH_WRAPPERS if french else ENGLISH_WRAPPERS
    shape = rng.randrange(4)
    if shape == 0:
        return f"{rng.choice(prefixes)} {name.lower()} {rng.choice(suffixes)}"
    if shape == 1:
        return f"{name} {rng.choice(contexts)}"
    if shape == 2:
        return rng.choice(wrappers).format(text=name.lower())
    return f"{name.lower()} {rng.choice(contexts)} {rng.choice(suffixes)}"


by_slug = defaultdict(list)
for line in ENTITIES_PATH.read_text().splitlines():
    e = json.loads(line)
    by_slug[e["slug"]].append((e["name"], origin(e.get("countries"))))

rng = random.Random(42)
train, test = [], []
for index, slug in enumerate(sorted(by_slug)):
    rows = sorted(set(by_slug[slug]))
    rng.shuffle(rows)
    rows = rows[:CAP]
    if len(rows) < 8:
        continue
    cut = int(len(rows) * 0.8)
    train += [(n, o, index) for n, o in rows[:cut]]
    test += [(n, o, index) for n, o in rows[cut:]]

forms = {
    "nom nu": lambda n: n,
    "phrase FR": lambda n: phrase(n, rng, french=True),
    "phrase EN": lambda n: phrase(n, rng, french=False),
}
train_texts = [f(n) for f in forms.values() for n, _, _ in train]
train_y = [y for _ in forms for _, _, y in train]
test_sets = {label: [f(n) for n, _, _ in test] for label, f in forms.items()}

counts = defaultdict(int)
for _, o, _ in test:
    counts[o] += 1
print(f"{len(train_texts)} train / {len(test)} test x3 formes — {dict(counts)}\n", flush=True)


def embed(repo, texts, tok, model):
    out = []
    for start in range(0, len(texts), BATCH):
        enc = tok(texts[start:start + BATCH], return_tensors="pt", padding=True,
                  truncation=True, max_length=MAX_LENGTH)
        with torch.no_grad():
            hidden = model(**enc).last_hidden_state
        mask = enc["attention_mask"].unsqueeze(-1).float()
        pooled = (hidden * mask).sum(1) / mask.sum(1).clamp(min=1e-9)
        out.append(torch.nn.functional.normalize(pooled, dim=-1).numpy())
    return np.concatenate(out)


for repo in sys.argv[1:]:
    tok = AutoTokenizer.from_pretrained(repo)
    model = AutoModel.from_pretrained(repo, dtype=torch.float32).eval()
    probe = LogisticRegression(max_iter=2000, C=10.0).fit(
        embed(repo, train_texts, tok, model), train_y)
    print(repo, flush=True)
    header = "  {:24s}".format("") + "".join(f"{k:>12s}" for k in forms)
    print(header, flush=True)
    predicted = {k: probe.predict(embed(repo, v, tok, model)) for k, v in test_sets.items()}
    for label in ("entite francaise", "entite anglophone", "entite internationale", "TOUTES"):
        rows = [i for i, (_, o, _) in enumerate(test) if label == "TOUTES" or o == label]
        cells = "".join(
            f"{sum(predicted[k][i] == test[i][2] for i in rows) / len(rows):>11.1%} " for k in forms)
        print(f"  {label:24s}{cells}({len(rows)})", flush=True)
    print(flush=True)
