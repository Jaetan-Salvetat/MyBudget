# Quick-Add Flow

## Architecture

Pipeline 100% on-device, déterministe hors modèle : regex + BERT multi-head ONNX. Une seule passe modèle, pas de LLM, pas de réseau.

```
User input (texte libre)
  │
  ▼ ~0ms
[REGEX] PriceParserService — extraction montant
  │
  ▼ ~100ms
[BERT multi-head ONNX] type + catégorie (55 classes) + récurrence
  │
  ▼
[Taxonomie] classe → groupe (13 groupes user-facing)
  │
  ▼
UI: carte de confirmation → Confirmer / Modifier (formulaire complet)
```

## Modèle

| Élément | Valeur |
|---|---|
| Backbone | mmBERT-small (ModernBERT, 384 hidden dim) |
| Têtes | type (expense/income) · catégorie (55) · récurrence (ponctuel/fixe) |
| Format | ONNX int8, ~135 MB, embarqué dans les assets |
| Latence | ~100ms sur device |
| Scores | easy 100% · medium 100% · hard : type 100%, cat 80%, rec 96% |

## Couche 1 — Regex (~0ms)

`PriceParserService` : extraction du montant depuis le texte brut.

- Formats : `12`, `3,50`, `13.99`, `1 200`, `2,500.50`
- Strip : `€ $ £`, "balles", "euros", "dollars"…
- Plusieurs nombres → le dernier gagne (`"2 pizzas 24"` → 24)
- Aucun montant → `QuickAddNoAmountException`, carte d'erreur

Le texte restant, nettoyé, sert d'input au modèle et de nom à la transaction (première lettre capitalisée).

## Couche 2 — BERT multi-head (~100ms)

`QuickAddTokenizer` (BPE, max_length 64) → `QuickAddModelRunner` (ONNX, 3 outputs en 1 pass) → argmax + softmax confidence par tête.

Les labels de sortie sont dans `QuickAddLabels` et doivent rester synchronisés avec l'ordre du training (`quick-add-3/multi-head-v1`).

## Couche 3 — Résolution catégorie

La classe prédite (`restauration.fast-food/friterie`) est réduite à son groupe (`restauration`) via `CategoryTaxonomyService` (`assets/categories.json` : label, icône, couleur par groupe).

- **Expense** : matching du groupe contre les catégories user (nom normalisé : minuscules, sans accents). Match → `categoryId`. Sinon → proposition "nouvelle catégorie" (badge sur la carte), créée à la confirmation avec l'icône/couleur de la taxonomie.
- **Income** : pas de catégorie (les revenus n'en ont pas), création d'un `RevenueModel`.

## Récurrence → Fréquence

| Prédiction | Fréquence |
|---|---|
| `ponctuel` | Ponctuel |
| `fixe` | Mensuel (ajustable en Annuel via "Modifier") |

## Revenue vs Expense

Même pipeline, même carte. Le type est prédit par le modèle (tête dédiée, 100% sur le jeu de test). La carte adapte libellé ("1 revenu détecté"), signe et couleur du montant, et le formulaire complet ouvert par "Modifier" (`RevenueBottomSheet` vs `ExpenseBottomSheet`).

## Pistes futures

- **Correction memory** : mémoriser les corrections user (`"mc do" → Loisirs`) pour court-circuiter le modèle sur les merchants déjà vus.
- **Seuil de confiance** : sous un seuil de `categoryConfidence`, ouvrir directement le picker de catégorie au lieu de suggérer.
- **Sous-catégories** : la classe fine (55) est disponible dans `QuickAddClassification.taxonomyCategory`, exploitable pour des stats plus fines.
