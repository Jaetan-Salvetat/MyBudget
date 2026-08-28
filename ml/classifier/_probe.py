"""Sonde lineaire : combien de connaissance categorielle sur nos noms est deja
dans un backbone gele, avant tout fine-tune.

On encode le nom nu, on gele, on entraine une regression logistique dessus, et
on mesure sur des entites jamais vues. C'est une comparaison relative entre
backbones — le fine-tune fera mieux partout, mais l'ordre se lit ici pour un
centieme du calcul.
"""
import json, random, sys
from collections import defaultdict

import numpy as np
import torch
from sklearn.linear_model import LogisticRegression
from transformers import AutoModel, AutoTokenizer

from paths import ENTITIES_PATH

CAP = 400          # par classe : les 4 800 compagnies aeriennes ecraseraient le reste
MAX_LENGTH = 32
BATCH = 128

by_slug = defaultdict(list)
for line in ENTITIES_PATH.read_text().splitlines():
    e = json.loads(line)
    by_slug[e["slug"]].append(e["name"])

rng = random.Random(42)
train_names, train_y, test_names, test_y = [], [], [], []
slugs = sorted(by_slug)
for index, slug in enumerate(slugs):
    names = sorted(set(by_slug[slug]))
    rng.shuffle(names)
    names = names[:CAP]
    if len(names) < 8:
        continue
    cut = int(len(names) * 0.8)
    train_names += names[:cut]; train_y += [index] * cut
    test_names += names[cut:];  test_y += [index] * (len(names) - cut)

print(f"{len(train_names)} noms d'entrainement, {len(test_names)} de test, "
      f"{len(set(train_y))} classes\n", flush=True)


def embed(repo: str, names: list[str]) -> np.ndarray:
    tok = AutoTokenizer.from_pretrained(repo)
    model = AutoModel.from_pretrained(repo, dtype=torch.float32).eval()
    out = []
    for start in range(0, len(names), BATCH):
        batch = names[start:start + BATCH]
        enc = tok(batch, return_tensors="pt", padding=True, truncation=True, max_length=MAX_LENGTH)
        with torch.no_grad():
            hidden = model(**enc).last_hidden_state
        mask = enc["attention_mask"].unsqueeze(-1).float()
        pooled = (hidden * mask).sum(1) / mask.sum(1).clamp(min=1e-9)
        out.append(torch.nn.functional.normalize(pooled, dim=-1).numpy())
        print(f"\r  {start + len(batch)}/{len(names)}", end="", file=sys.stderr)
    return np.concatenate(out)


for repo in sys.argv[1:]:
    try:
        train_x = embed(repo, train_names)
        test_x = embed(repo, test_names)
        probe = LogisticRegression(max_iter=2000, C=10.0).fit(train_x, train_y)
        print(f"\r{repo:32s} dim={train_x.shape[1]:5d}  sonde lineaire "
              f"{probe.score(test_x, test_y):.1%}", flush=True)
    except Exception as e:
        print(f"\r{repo:32s} ERR {type(e).__name__}: {str(e)[:90]}", flush=True)
