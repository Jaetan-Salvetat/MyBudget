# Quick-Add AI

Analyse d'une saisie en langage naturel vers une transaction structurée, 100% on-device via un modèle BERT multi-head embarqué (ONNX). Aucun téléchargement, aucun cloud.

```
"resto italien 25" → { type: expense, name: "Resto italien", amount: 25.0,
                       category: "Restauration", frequency: "Ponctuel" }
"salaire 2500"     → { type: income, name: "Salaire", amount: 2500.0,
                       frequency: "Mensuel" }
```

## Architecture

```
Texte utilisateur
  │
  ▼ ~0ms
[PriceParserService]  regex montant (FR/EN, symboles, "balles"/"euros")
  │
  ▼ texte nettoyé
[QuickAddTokenizer]   BPE, max_length=64
  │
  ▼
[QuickAddModelRunner] ONNX multi-head (mmBERT-small int8, ~135 MB) — 1 pass :
  │                     type_logits (expense/income)
  │                     category_logits (55 classes)
  │                     recurrence_logits (ponctuel/fixe)
  ▼
[CategoryTaxonomyService] classe → groupe (13 groupes, assets/categories.json)
  │
  ▼
[QuickAddNotifier]    matching catégories user (ou création auto icône+couleur)
                      → carte de confirmation → ExpenseModel / RevenueModel
```

## Fichiers

- `lib/core/services/quick_add/` — pipeline complet (parser, tokenizer, runner, taxonomie, classifier)
- `lib/core/constants/quick_add_labels.dart` — labels des 3 têtes (doivent matcher l'ordre du training)
- `lib/ui/quick_add/` — notifier + widgets (input bar, cartes confirmation/loading/erreur)
- `assets/models/model.onnx` + `assets/models/tokenizer.json` — modèle et tokenizer
- `assets/categories.json` — taxonomie 55 sous-catégories / 13 groupes (label, icône, couleur)

## Modèle

- **Backbone** : `jhu-clsp/mmBERT-small`, 3 têtes, mean pooling, quantization int8
- **Training** : `~/Documents/dev/projects/mybudget-locale-ai/quick-add-3/` (dataset FR/EN/ES/DE, scripts `generate_dataset.py` / `train.py` / `test_model.py` / `export_onnx.py`)
- **Scores (2026-07-10)** : easy 100% · medium 100% · hard — type 100%, catégorie 80%, récurrence 96%
- Après ré-entraînement : copier `output/model.onnx` et `output/best/tokenizer.json` dans `assets/models/`, garder `QuickAddLabels` synchronisé

## Règles métier

- Montant obligatoire : sans montant détecté → `QuickAddNoAmountException` (carte d'erreur)
- Catégorie = groupe de la taxonomie (ex. `restauration.café` → "Restauration")
- Income : pas de catégorie (les revenus n'en ont pas), `RevenueModel` créé
- Récurrence `fixe` → fréquence "Mensuel", `ponctuel` → "Ponctuel" (modifiable via le formulaire complet)
- Matching catégorie existante : nom normalisé (minuscules, sans accents) ; sinon création avec icône/couleur de la taxonomie

## Status

- [x] Benchmark et pivot LLM → BERT multi-head (l'ancienne stack Gemma/LiteRT/OpenRouter a été supprimée)
- [x] Modèle entraîné, quantizé int8, validé dans `pipeline_app`
- [x] Pipeline Dart intégré (tokenizer BPE, ONNX runtime, taxonomie)
- [x] QuickAddNotifier branché (dépenses + revenus, création auto de catégorie)
- [x] Tests unitaires (parser, tokenizer, taxonomie, classifier, notifier)
- [ ] Test sur device physique Android
