# Correction Memory Flow

## Principe

Cache local qui apprend des confirmations et corrections de l'user. Court-circuite CamemBERT + Gemma pour les merchants déjà vus.

## Schéma ObjectBox — CorrectionMemoryModel

```
@Entity()
class CorrectionMemoryModel {
  int id;
  String inputPattern;       // "mc do", "netflix", "ostéo"
  String categoryName;       // "Restauration"
  String? normalizedName;    // "McDonald's"
  String? icon;              // "restaurant"
  String type;               // "expense" / "revenue"
  String frequency;          // "monthly" / "annual" / "oneTime"
  int correctionCount;       // nombre de fois corrigé
  bool unstable;             // true si correctionCount > 3
  DateTime lastUsed;
  DateTime createdAt;
}
```

## Pipeline

### Écriture (après confirmation user)

```
User confirme "mc do" → Restauration
  │
  ▼
Lookup "mc do" dans CorrectionMemory
  ├─ Existe → update (categoryName, lastUsed, reset correctionCount si changé)
  └─ N'existe pas → insert
```

### Écriture (après correction user)

```
Carte affiche: 🍔 Restauration
User corrige → Loisirs
  │
  ▼
Lookup "mc do"
  ├─ Existe → update categoryName="Loisirs", correctionCount++
  │           si correctionCount > 3 → unstable = true
  └─ N'existe pas → insert avec correctionCount = 1
```

### Lecture (avant chaque quick-add)

```
Input: "mc do 15€"
  │
  ▼ <1ms
[MEMORY] normalize("mc do") → lookup
  ├─ HIT + !unstable → carte complète immédiate, skip ML
  ├─ HIT + unstable  → afficher picker catégorie au lieu de suggestion auto
  └─ MISS            → pipeline normal (CamemBERT → Gemma)
```

## Normalisation de l'input

Avant le lookup, normaliser le pattern :
- Lowercase
- Strip accents
- Trim whitespace
- Strip montant et mots-clés monétaires

```
"Mc Do 12 balles" → "mc do"
"NETFLIX"         → "netflix"
"ostéo"           → "osteo"
```

## Évolution dans le temps

| Période | % memory hit | Latence moyenne |
|---|---|---|
| Semaine 1 | ~10% | ~0.8s |
| Semaine 3 | ~50% | ~0.4s |
| Mois 2+ | ~70% | ~0.2s |

## Flag "unstable"

Un mapping corrigé >3 fois est marqué instable. L'app arrête de suggérer automatiquement et affiche le picker catégorie.

Cas typique : "café" peut être Restauration ou Loisirs selon le contexte. Le système apprend qu'il ne peut pas décider seul.

## Cleanup

- Entrées non utilisées depuis >6 mois → suppression automatique
- Au delete d'une catégorie → supprimer toutes les entrées memory qui y réfèrent
