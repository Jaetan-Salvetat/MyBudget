# Category Flow

## Principes

- Les catégories sont créées **à l'usage**, pas en amont
- L'user ne configure jamais de catégorie manuellement (sauf s'il le veut)
- Couleur et icône sont automatiques
- Les doublons sont détectés et mergés automatiquement

## Création automatique (via Quick-Add)

### Déclencheur

Gemma 0.5B retourne `isNew: true` quand aucune catégorie existante ne matche les semantic_tags de CamemBERT.

### Pipeline

```
CamemBERT: semantic_tags = ["soin", "santé", "praticien"]
  │
  ▼
Gemma 0.5B: aucune catégorie existante ne colle
  │
  ▼
Output: { category: "Santé", isNew: true, icon: "health_and_safety" }
  │
  ▼
[ALGO] Near-duplicate check
  │
  ▼
[ALGO] Color = fnv32("Santé") % palette.length
  │
  ▼
[ALGO] Icon validation: isValidIcon("health_and_safety") → true
  │
  ▼
Catégorie créée dans ObjectBox
  │
  ▼
UI: carte de confirmation affiche la nouvelle catégorie
```

### Couleur

Déterministe via hash du nom.

```dart
int color = palette[fnv32(categoryName) % palette.length];
```

- Même nom → même couleur, toujours
- Pas d'input user
- Palette définie dans `category_defaults.dart`

### Icône

Générée par le LLM (nom Material Symbols).

```
Gemma output: icon = "health_and_safety"
  │
  ▼
isValidIcon("health_and_safety") → true → utiliser
isValidIcon("blabla_invalid")    → false → fallback "category"
```

- Pas de keyword lookup table
- Pas de mapping hardcodé
- i18n-friendly : le LLM génère l'icône quel que soit la langue de l'input

### Near-Duplicate Detection

Avant de créer une catégorie, vérifier qu'elle n'existe pas déjà sous un nom proche.

```
Nouvelle: "Cafés"
Existante: "Café"

Levenshtein distance = 1
Threshold: < 2 edits → merge automatique vers l'existante

Nouvelle: "Resto"
Existante: "Restauration"

Levenshtein distance = 8
Threshold: ≥ 2 edits → catégorie distincte, pas de merge
```

Cas supplémentaire — normalisation avant comparaison :
- Lowercase
- Strip accents
- Strip pluriel (trailing "s")

```
"Cafés" → "cafe"
"Café"  → "cafe"
→ identiques → merge
```

## Catégories par défaut

Supprimées à l'onboarding. L'app démarre avec **zéro catégorie**. Elles se construisent au fil des entrées.

### Migration users existants

Les users qui ont déjà des catégories les gardent. Le nouveau flow s'applique uniquement aux nouvelles catégories. Feature flag pour la transition.

## Gestion manuelle

L'user peut toujours :
- Renommer une catégorie
- Changer l'icône
- Changer la couleur
- Supprimer une catégorie (avec réassignation des transactions)

Accessible via Settings > Catégories. Jamais dans le chemin critique du quick-add.

## Correction et apprentissage

### Correction sur la carte de confirmation

```
Carte affiche: 🍔 Restauration
User tape sur la catégorie → picker catégories
User choisit "Loisirs"
  │
  ▼
[MEMORY] Store: { "mc do" → "Loisirs" }
```

La prochaine fois, "mc do" → "Loisirs" directement (memory hit, pas de LLM).

### Compteur de corrections

Si un mapping est corrigé >3 fois → flag interne "instable". Forcer l'affichage du picker catégorie au lieu de la suggestion auto pour ce merchant.

## Lifecycle d'une catégorie

```
                    Quick-add "ostéo 45€"
                           │
                           ▼
                   CamemBERT: tags = ["santé", "soin"]
                           │
                           ▼
                   Gemma: "Santé", isNew=true, icon=health_and_safety
                           │
                           ▼
                   Near-dup check: pas de doublon
                           │
                           ▼
         ┌─── Catégorie "Santé" créée ───┐
         │  color: fnv32("Santé") % N    │
         │  icon: health_and_safety      │
         │  source: auto                 │
         └───────────────────────────────┘
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
     "kiné 60€"     "pharmcie 8€"   "dentiste 120€"
     memory miss     memory miss     memory miss
     tags=santé      tags=pharma     tags=dentaire
     → Santé ✓       → Santé ✓      → Santé ✓
            │              │              │
            ▼              ▼              ▼
     memory store    memory store    memory store
     kiné→Santé      pharmcie→Santé  dentiste→Santé
```

## Schéma ObjectBox — CategoryModel

Champs existants (inchangés) :
- `id` (int, auto)
- `name` (String)
- `icon` (String) — nom Material Symbols au lieu d'un keyword
- `color` (int, ARGB)

Nouveau champ :
- `source` (String) — `"auto"` ou `"manual"`. Permet de distinguer les catégories créées par l'IA de celles créées manuellement.

## Limites

| Contrainte | Gestion |
|---|---|
| LLM génère une icône invalide | `isValidIcon()` → fallback `category` |
| Near-dup rate trop haut (false positives) | Abaisser le seuil ou ajouter confirmation user |
| Trop de catégories (>50) | UX warning dans Settings, pas de hard limit |
| Catégorie vide (0 transactions) | Cleanup automatique après 3 mois d'inactivité |
