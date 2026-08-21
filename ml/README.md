# ML — Quick-Add

Entraînement du classifieur on-device du quick-add. Les sources vivent ici, les artefacts
(venv, checkpoints, dataset) sont générés localement et gitignorés.

```
ml/
├── quick_add/           # Training Python (mmBERT-small multi-head)
│   ├── generate_dataset.py   # Génération du dataset FR/EN/ES/DE (SEED = 42)
│   ├── examples.py           # Exemples de base par slug (source de la génération)
│   ├── train.py              # Entraînement multi-head
│   ├── test_model.py         # Évaluation du modèle
│   ├── export_onnx.py        # Export ONNX + quantization int8
│   └── eval_corpus.json      # Corpus de validation étiqueté à la main
└── price_parser/        # Prototype Dart d'extraction de prix (regex)
```

## Architecture du modèle

```
Texte utilisateur
      ↓  [Price Parser]        montant (regex, portée par PriceParserService côté app)
  texte nettoyé
      ↓  [BPE Tokenizer]       input_ids + attention_mask (max_length = 64)
      ↓  [ONNX Model]          type_logits (2) | category_logits (75) | recurrence_logits (2)
  argmax par tête
```

- Backbone : `jhu-clsp/mmBERT-small` (ModernBERT, 384 hidden dim)
- Heads : Dense(no bias) → GELU → LayerNorm(no bias) → Dropout → Linear(bias)
- Pooling : mean pooling
- Quantization : int8 dynamique (~135 Mo)

## Taxonomie

La source de vérité est `assets/categories.json` à la racine du projet — **pas un fichier
de ce dossier**. L'ordre des classes est le contrat entre le modèle et l'app :

```bash
dart run tool/generate_taxonomy_labels.dart --stdout   # 75 slugs, dans l'ordre des index
```

Voir `docs/taxonomy.md` pour les règles d'évolution.

## Pipeline

```bash
cd ml/quick_add
uv run python generate_dataset.py   # → dataset/train.jsonl + eval.jsonl
uv run python train.py              # → output/best/  (~40 min sur Apple Silicon MPS)
uv run python test_model.py         # évaluation
uv run python export_onnx.py        # → output/model.onnx
```

Déploiement dans l'app :

```bash
cp output/model.onnx        ../../assets/models/model.onnx
cp output/best/tokenizer.json ../../assets/models/tokenizer.json
```

`assets/models/` est suivi par git LFS.

## Modifier la taxonomie

1. Éditer `assets/categories.json` et bumper `version`
2. `dart run tool/generate_taxonomy_labels.dart`
3. Ajuster `CategoryTaxonomyService.expectedVersion`
4. Ajouter les exemples correspondants dans `examples.py`, indexés par slug
5. Relancer la pipeline complète, puis redéployer

`LABELS`, `NUM_EXPENSE` et `NUM_CATEGORIES` sont dérivés de la taxonomie : aucun nombre de
classes n'est écrit en dur. `generate_dataset.py` échoue si un slug n'a pas d'exemples ou si
`examples.py` référence un slug inconnu.

Les tests `test/unit/taxonomy/taxonomy_asset_test.dart` vérifient que labels, taxonomie et
corpus restent alignés.

## Prérequis

Python ≥ 3.11 + `uv`, ~4 Go de RAM pour l'entraînement.
