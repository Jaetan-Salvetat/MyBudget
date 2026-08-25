# ML — Quick-Add

Entraînement du classifieur on-device du quick-add. Les sources vivent ici, les
artefacts (venv, checkpoints, dataset, cache des sources) sont générés
localement et gitignorés.

**La marche à suivre complète est dans [`quick_add/TRAINING.md`](quick_add/TRAINING.md).**

```
ml/
├── quick_add/
│   ├── taxonomy.py           # Chargement des 80 classes depuis assets/categories.json
│   ├── knowledge/            # Moisson de la connaissance monde → dataset/entities.jsonl
│   │   ├── build.py          #   fusion, arbitrage des conflits, liste des ambiguïtés
│   │   ├── entities.py       #   modèle commun, normalisation des noms
│   │   ├── mapping_nsi.py    #   chemins OSM → slugs de la taxonomie
│   │   ├── audit.py          #   échantillon déterministe à relire à la main
│   │   └── sources/          #   services, lexicon, nsi, wikidata, openfoodfacts, patterns
│   ├── examples.py           # Exemples curés par slug, écrits à la main
│   ├── generate_dataset.py   # entités + exemples → train.jsonl / eval.jsonl
│   ├── train.py              # Entraînement multi-tête
│   ├── eval_world.py         # Connaissance monde : mémorisation vs généralisation
│   ├── test_model.py         # Non-régression sur eval_corpus.json
│   ├── export_onnx.py        # Export ONNX + quantization int8
│   ├── test_onnx.py          # Vérifie l'artefact livré : justesse et fidélité
│   ├── eval_world.json       # 294 cas FR/EN étiquetés à la main, par axe
│   ├── eval_corpus.json      # 157 cas historiques
│   ├── eval_receipts.json    # 5 005 libellés de tickets FindIt étiquetés (scan)
│   ├── receipts/             # Corpus « style ticket » et cascade du scan (TRAINING.md §8)
│   └── tests/                # Tests des invariants du pipeline
└── price_parser/             # Prototype Dart d'extraction de prix (regex)
```

## Architecture du modèle

```
Texte utilisateur
      ↓  [Price Parser]        montant (regex, porté par PriceParserService côté app)
  texte nettoyé
      ↓  [BPE Tokenizer]       input_ids + attention_mask (padding dynamique)
      ↓  [ONNX Model]          type_logits (2) | category_logits (80) | recurrence_logits (2)
  argmax par tête
```

- Backbone : `jhu-clsp/mmBERT-small` (ModernBERT, 384 dim, 22 couches)
- Heads : Dense(no bias) → GELU → LayerNorm(no bias) → Dropout → Linear(bias)
- Pooling : mean pooling
- Quantization : int8 dynamique (~135 Mo)

## Taxonomie

La source de vérité est `assets/categories.json` à la racine du projet — **pas
un fichier de ce dossier**. L'ordre des classes est le contrat entre le modèle
et l'app :

```bash
dart run tool/generate_taxonomy_labels.dart --stdout   # 80 slugs, dans l'ordre des index
```

Toute modification de la taxonomie impose un réentraînement : un modèle entraîné
sur N classes servi derrière N+k labels décale silencieusement toutes ses
prédictions. Voir la section 6 de `TRAINING.md`.

## Pipeline

```bash
cd ml/quick_add
uv run python -m knowledge.build    # → dataset/entities.jsonl  (~28 600 entités)
uv run python generate_dataset.py   # → dataset/train.jsonl + eval.jsonl
uv run python train.py              # → output/best/            (~2 h sur MPS)
uv run python eval_world.py         # connaissance monde
uv run python test_model.py         # non-régression
uv run python export_onnx.py        # → output/model.onnx
uv run python test_onnx.py          # justesse et fidélité de l'export int8
uv run python -m receipts.evaluate --cascade   # libellés de tickets (scan)
uv run python -m pytest             # invariants du pipeline
```

Déploiement dans l'app :

```bash
cd ../.. && ./tool/publish_model.sh   # asset versionné + release GitHub + tool/model.lock
```

## Artefacts locaux

`output/`, `dataset/` et `.venv/` sont gitignorés. Après un run il ne doit
rester que :

```
output/best/          ~600 Mo   poids PyTorch du modèle retenu
output/model.onnx     ~135 Mo   export int8 déployé dans assets/
dataset/entities.jsonl  ~8 Mo   base de connaissance fusionnée
dataset/cache/         ~20 Mo   sources téléchargées, réutilisables
```

`output/best/` est le seul exemplaire des poids du modèle livré : sans lui,
ré-exporter l'ONNX impose un ré-entraînement, dont le résultat ne sera pas
identique (MPS n'est pas déterministe au bit près malgré `SEED = 42`).

Les `checkpoint-*` ne servent qu'à reprendre un entraînement interrompu ;
`save_total_limit` en borne l'accumulation dans `train.py`.

`tool/cleanup.sh` ramène `ml/` à cet état — en simulation par défaut, `--apply`
pour supprimer, `--min-free 50` pour ne libérer que le nécessaire en cours de
run. Les checkpoints sont épargnés tant qu'un `train.py` tourne :

```bash
./tool/cleanup.sh                                  # ce qui serait supprimé
./tool/cleanup.sh --apply                          # caches, checkpoints, export périmé
./tool/cleanup.sh --datasets --backups --hf-cache --apply
./tool/cleanup.sh quick_add --apply                # un seul projet
```

## Prérequis

Python ≥ 3.11 + `uv`, ~4 Go de RAM pour l'entraînement, une connexion pour la
première moisson.
