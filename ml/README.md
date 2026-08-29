# ML

Deux briques, un artefact partagé.

```
ml/
├── classifier/     # le modèle BERT multi-tête — transversal quick-add + scan
├── scan/           # OCR + structuration de tickets — spécifique
└── price_parser/   # prototype Dart d'extraction de prix (regex)
```

`price_parser/` est un prototype dépassé : sa logique vit désormais dans
`lib/core/services/quick_add/price_parser_service.dart`.

## Le sens des dépendances

```
scan/data/golden  ──────────────►  classifier/corpus/receipts   vérité terrain → corpus
scan/research/reference  ───────►  (libellés d'articles)        sortie OCR → entrée modèle
classifier/output/best/model.onnx ►  assets/  ──►  lib/ + scan/pipeline
classifier/serving/  ═══ parité ═══  scan/pipeline/lib/src/normalize.dart
```

Acyclique, et c'est l'invariant à tenir : le scan alimente le classifieur en
données, le classifieur livre un artefact que les deux consomment. Rien ne
remonte du classifieur vers le scan sauf le `.onnx`. Un module qui remonte
l'arborescence à la main pour aller chercher l'autre brique est un bug —
`classifier/paths.py` et `scan/research/paths.py` sont les seuls endroits où
un chemin inter-briques est écrit.

## classifier/

Un seul modèle sert les deux consommateurs : le quick-add lui apporte du
phrasé utilisateur, le scan des libellés « style ticket ». Marche à suivre
complète : [`classifier/README.md`](classifier/README.md).

```
classifier/
├── taxonomy.py           # les 80 classes, contrat modèle ↔ app
├── knowledge/            # moisson de la connaissance monde → dataset/entities.jsonl
├── corpus/
│   ├── quick_add/        #   phrasé utilisateur français : exemples curés + génération
│   └── receipts/         #   style caisse : lexique, déformation, vérité FindIt
├── serving/              # contrat d'entrée/sortie — miroir Dart obligatoire
├── training/             # entraînement, finetune, export ONNX int8
├── evaluation/           # world / generalization / quick_add / receipts / ONNX
└── tests/                # invariants du pipeline
```

```bash
cd ml/classifier
uv run python -m knowledge.build            # → dataset/entities.jsonl (~28 600 entités)
uv run python -m corpus.quick_add.build     # → dataset/train.jsonl + eval.jsonl
uv run python -m corpus.receipts.build      # → dataset/receipts_*.jsonl
uv run python -m training.train             # → output/best/ (~2 h sur MPS)
uv run python -m evaluation.world           # mémorisation
uv run python -m evaluation.generalization  # entités jamais vues — la mesure qui décide
uv run python -m evaluation.quick_add       # non-régression quick-add
uv run python -m evaluation.robustness      # fautes de frappe, par opérateur
uv run python -m evaluation.receipts --cascade   # libellés de tickets (scan)
uv run python -m training.export_onnx       # → output/best/model.onnx
uv run python -m evaluation.onnx            # justesse et fidélité de l'export int8
uv run python -m pytest                     # invariants du pipeline
```

Déploiement dans l'app :

```bash
cd ../.. && ./tool/models/publish.sh   # asset versionné + release GitHub + tool/models/lock.env
```

### Architecture du modèle

```
Texte utilisateur / libellé de ticket
      ↓  [Price Parser]        montant (regex, PriceParserService côté app)
      ↓  [serving/normalize]   minuscules, accents repliés, ponctuation décollée
                               — la forme exacte du corpus, des deux côtés
      ↓  [BPE Tokenizer]       input_ids + attention_mask (padding dynamique)
      ↓  [ONNX Model]          type_logits (2) | category_logits (80) | recurrence_logits (2)
  argmax par tête
      ↓  [serving/cascade]     décision de catégorie d'un ticket (enseigne → articles)
```

- Backbone : `jhu-clsp/mmBERT-small` (ModernBERT, 384 dim, 22 couches)
- Heads : Dense(no bias) → GELU → LayerNorm(no bias) → Dropout → Linear(bias)
- Pooling : mean pooling
- Quantization : int8 dynamique (~135 Mo)

### Taxonomie

La source de vérité est `assets/categories.json` à la racine du projet — **pas
un fichier de ce dossier**. L'ordre des classes est le contrat entre le modèle
et l'app :

```bash
dart run tool/generate_taxonomy_labels.dart --stdout   # 80 slugs, dans l'ordre des index
```

Toute modification de la taxonomie impose un réentraînement : un modèle entraîné
sur N classes servi derrière N+k labels décale silencieusement toutes ses
prédictions. Voir la section 6 de `classifier/README.md`.

## scan/

Photo de ticket → articles, prix, remises, total, date, 100 % on-device.
Détail, mesures et décisions : [`scan/README.md`](scan/README.md).

```
scan/
├── research/     # la recherche, en Python (référence, vérité, corpus, bench)
├── pipeline/     # package Dart receipt_pipeline — le portage livré
├── harness/      # banc Flutter on-device
└── data/         # corpus et dumps OCR, gitignorés sauf data/golden/
```

```bash
cd ml/scan/research
uv run python -m pytest              # invariants du pipeline de référence
uv run python -m bench.parity        # parité Dart ↔ Python, 0 divergence attendue
uv run python -m bench.local --ml    # le bench central : mode local sur 899 tickets
./fetch_data.sh                      # reconstruit les sélections et le synthétique
```

## Corpus d'entraînement

Rien de tout ça n'est versionné : les corpus vivent dans un dépôt Hugging Face
**privé**, seul endroit où FindIt peut tenir sans enfreindre sa licence de
recherche. Le dépôt est un miroir exact de `ml/`, épinglé par révision.

```bash
./tool/ml_data/fetch.sh --list        # l'inventaire
./tool/ml_data/fetch.sh               # tout (~6,7 Go)
./tool/ml_data/fetch.sh annotations   # ~57 Mo, suffit à entraîner le tagger
./tool/ml_data/publish.sh --dry-run   # ce qui repartirait
```

Publier **synchronise** : ce qui a disparu en local disparaît côté distant.
D'où le refus de publier un corpus absent de la machine — après un clone
frais, ce serait vider le dépôt.

## Artefacts locaux

`output/`, `dataset/`, `data/` (sauf `data/golden/`) et `.venv/` sont
gitignorés. Après un run il ne doit rester dans `classifier/` que :

```
output/best/          ~600 Mo   poids PyTorch du modèle retenu
output/best/model.onnx ~135 Mo  son export int8, déployé dans assets/
dataset/entities.jsonl  ~8 Mo   base de connaissance fusionnée
dataset/cache/         ~20 Mo   sources téléchargées, réutilisables
```

L'ONNX vit dans le dossier des poids dont il sort, et `registry.env` ne
désigne que celui-là : livrer un autre run consiste à en faire `output/best`,
jamais à publier un export posé ailleurs. Un export et des poids qui se
choisissent séparément divergent — cinq versions du quick-add ont été publiées
depuis un export périmé avant que ce lien ne soit rendu structurel.

`output/best/` est le seul exemplaire des poids du modèle livré : sans lui,
ré-exporter l'ONNX impose un ré-entraînement, dont le résultat ne sera pas
identique (MPS n'est pas déterministe au bit près malgré `SEED = 42`).

Les `checkpoint-*` ne servent qu'à reprendre un entraînement interrompu ;
`save_total_limit` en borne l'accumulation dans `training/train.py`.

`tool/cleanup.sh` ramène `ml/` à cet état — en simulation par défaut, `--apply`
pour supprimer, `--min-free 50` pour ne libérer que le nécessaire en cours de
run. Les checkpoints sont épargnés tant qu'un `train.py` tourne :

```bash
./tool/cleanup.sh                                  # ce qui serait supprimé
./tool/cleanup.sh --apply                          # caches, builds Dart, checkpoints
./tool/cleanup.sh --datasets --backups --hf-cache --raw --apply
./tool/cleanup.sh classifier --apply               # un seul projet
```

Jamais touchés : `scan/data/golden/` (versionné) et `scan/data/results/` — les
dumps OCR device coûtent une nuit de run à régénérer.

## Prérequis

Python ≥ 3.11 + `uv`, ~4 Go de RAM pour l'entraînement, une connexion pour la
première moisson.
