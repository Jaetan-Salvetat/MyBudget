# Quick-Add Flow

## Architecture

3 couches de traitement séquentielles, 2 modèles ML + regex.

```
User input (texte libre)
  │
  ▼ 0ms
[REGEX] Extraction montant
  │
  ▼ ~100ms
[CamemBERT INT8] NER + classification + enrichissement sémantique
  │
  ▼ UI: carte partielle
  │
  ▼ ~0.5-0.7s
[Gemma 0.5B LoRA] Catégorisation + icône + normalisation
  │
  ▼ UI: carte complète
```

## Modèles

| Modèle | Taille | Latence | Rôle |
|---|---|---|---|
| CamemBERT INT8 | ~110 MB | ~100ms | NER, type, fréquence, tags sémantiques |
| Gemma 0.5B INT4 LoRA | ~300 MB | ~0.5-0.7s | Catégorisation, icône, normalisation nom |

Total on-device : ~410 MB.

## Couche 1 — Regex (0ms)

Extraction du montant depuis le texte brut.

```
Pattern : (\d+[.,]?\d*)
Strip : "balles", "euros", "€", "thunes", "euro"
Normalisation : "3,5" → 3.50 / "23.99" → 23.99
```

Déterministe, 100% fiable. Le montant est toujours un pattern numérique.

## Couche 2 — CamemBERT (~100ms)

CamemBERT est un encoder pré-entraîné sur du français. Il connaît le monde : il sait que "mc do" = fast-food, que "netflix" = streaming, que "ostéo" = santé. Il ne génère pas de texte, il classifie et tague.

### Output

```json
{
  "name": "mc do",
  "type": "expense",
  "frequency": "oneTime",
  "semantic_tags": ["fast-food", "restaurant", "chaîne"],
  "beneficiary_hint": null
}
```

### Tâches

| Champ | Méthode | Exemple |
|---|---|---|
| `name` | NER token-level | "mc do 12 balles" → `"mc do"` |
| `type` | Classification binaire (expense/revenue) | "ma sœur m'a filé 200€" → `revenue` |
| `frequency` | Classification 3 classes | "netflix" → `monthly`, "café" → `oneTime` |
| `semantic_tags` | Embedding → top-k concepts proches | "mc do" → `["fast-food", "restaurant", "chaîne"]` |
| `beneficiary_hint` | NER entité personne | "filé par Marie" → `"Marie"` |

### Semantic Tags

CamemBERT produit des tags sémantiques à partir de son pré-entraînement. Ces tags décrivent **ce qu'est** la dépense sans la catégoriser.

Exemples :

| Input | Tags |
|---|---|
| "mc do" | fast-food, restaurant, chaîne |
| "netflix" | streaming, divertissement, abonnement |
| "ostéo" | soin, santé, praticien |
| "shein" | e-commerce, mode, vêtements |
| "loyer" | logement, habitat, mensuel |
| "uber" | transport, VTC, mobilité |

Ces tags sont le **contexte** que le LLM consomme pour catégoriser. Le LLM n'a plus besoin de connaître le monde.

### UI après couche 2

Carte partielle affichée immédiatement :

```
╭──────────────────────────────╮
│  mc do          -12,00 €     │
│  Dépense · Ponctuel          │
│  ░░░░░░░░░░  (catégorie...)  │
╰──────────────────────────────╯
```

## Couche 3 — Gemma 0.5B LoRA (~0.5-0.7s)

Le LLM reçoit les tags sémantiques + la liste des catégories existantes. Son travail est réduit à du matching + génération si nécessaire.

### Prompt

```
semantic_tags: ["fast-food", "restaurant", "chaîne"]
categories: ["Restauration", "Abonnements", "Transport", "Santé", "Loyer"]

→ category, isNew, icon
```

### Output

```json
{
  "category": "Restauration",
  "isNew": false,
  "icon": "restaurant",
  "normalized_name": "McDonald's"
}
```

### Tâches

| Champ | Description |
|---|---|
| `category` | Catégorie existante qui matche les tags, ou nouveau nom si rien ne colle |
| `isNew` | `true` si aucune catégorie existante ne matche |
| `icon` | Nom d'icône Material Symbols généré par le LLM |
| `normalized_name` | Optionnel : "mc do" → "McDonald's" |

### Validation post-LLM

- `icon` : vérifier existence via `isValidIcon(name)`, fallback `category` si invalide
- `category` : si `isNew`, lancer near-duplicate check (Levenshtein)
- `normalized_name` : si null, garder le name brut de CamemBERT

### UI après couche 3

Carte complète :

```
╭──────────────────────────────╮
│  McDonald's     -12,00 €     │
│  Dépense · Ponctuel          │
│  🍔 Restauration             │
╰──────────────────────────────╯
```

## Correction Memory

Court-circuite tout le pipeline pour les merchants déjà vus.

```
User confirme "mc do" → Restauration
  │
  ▼
Store: { pattern: "mc do", category: "Restauration", icon: "restaurant", name: "McDonald's" }
```

Au prochain "mc do" :

```
Input: "mc do 15€"
  │
  ▼ <1ms
[MEMORY] lookup "mc do" → HIT
  │
  ▼
Carte complète immédiate, skip CamemBERT + Gemma
```

### Évolution dans le temps

| Période | % memory hit | % CamemBERT seul suffit | % LLM nécessaire |
|---|---|---|---|
| Semaine 1 | ~10% | ~30% | ~60% |
| Semaine 3 | ~50% | ~30% | ~20% |
| Mois 2+ | ~70% | ~20% | ~10% |

## Scénarios par latence

| Scénario | Qui travaille | Latence totale |
|---|---|---|
| Merchant connu (memory hit) | Personne | <1ms |
| Catégorie existante évidente | CamemBERT + Gemma | ~0.7s |
| Catégorie ambiguë | CamemBERT + Gemma | ~0.9s |
| Nouvelle catégorie | CamemBERT + Gemma (génère) | ~1.0s |

## Revenue vs Expense

Même pipeline, même appel, même carte. Le type est détecté par CamemBERT via analyse sémantique du verbe :

| Input | Verbe/contexte | Type |
|---|---|---|
| "salaire 2500€" | salaire = revenu implicite | revenue |
| "mc do 12€" | pas de verbe = dépense par défaut | expense |
| "ma sœur m'a filé 200€" | "filé" = donner (sujet=sœur, destinataire=moi) | revenue |
| "j'ai filé 50€ à Pierre" | "filé" = donner (sujet=moi, destinataire=Pierre) | expense |

## Beneficiary Flow

```
CamemBERT: beneficiary_hint = "Marie"
  │
  ▼
[FUZZY] match vs bénéficiaires existants
  ├─ "Marie Dupont" (score 0.92) → proposer
  └─ Aucun match → ignorer (pas d'auto-création)
```

Les bénéficiaires ne sont jamais auto-créés. Extraction + suggestion uniquement.

## Budget latence (contrainte 3s)

```
Regex:     ~0ms
CamemBERT: ~100ms
UI render: ~50ms
Gemma:     ~500-700ms
UI update: ~50ms
─────────────────
Total:     ~700ms - 900ms (bien sous les 3s)
```

Marge restante : ~2s pour animations, réseau (si fallback cloud), ou devices lents.
