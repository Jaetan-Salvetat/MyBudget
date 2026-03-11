# Audit couleur — MyBudget

## Contexte

Retour utilisateur : "l'app est trop fade en terme de couleur."

## Diagnostic

Le problème **n'est pas la couleur choisie** (`#1565C0` — bleu saturé correct), mais le fait que **l'app n'utilise quasiment pas de couleur**.

## Surfaces (100% de la surface visible)

| Composant | Couleur actuelle | Résultat visuel |
|---|---|---|
| FrostedCard | `colorScheme.surface` | Blanc |
| FrostedAppBar | `surface` à 70% alpha + blur | Blanc translucide |
| FrostedBottomNavigationBar | `surface` à 70% alpha + blur | Blanc translucide |
| FrostedBottomSheet | `surface` à 70% alpha + blur | Blanc translucide |
| Scaffold background | Default M3 | Blanc/gris très clair |
| FAB | `primaryContainer` M3 | Bleu très désaturé |

**Résultat** : l'UI entière est un bloc blanc uniforme.

## Accents colorés (seuls éléments non-blancs)

| Élément | Couleur | Opacité | Visibilité |
|---|---|---|---|
| Montants revenus | `colorScheme.primary` | 100% | Visible (texte seul) |
| Montants dépenses | `colorScheme.error` | 100% | Visible (texte seul) |
| Cercles icônes catégories | `category.color` | 10-20% | Quasi invisible |
| Badges montants | `primary` / `error` | 8-10% | Quasi invisible |
| Progress bars catégories | `category.color` | 100% | Visible |
| Progress bars emprunts | `colorScheme.primary` | 100% | Visible |
| Icônes settings | `primary` | 20% | Faible |
| Statut emprunts | `amber` / `blue` / `green` | 100% | Visible (petit indicateur) |

## Ce qui manque

- **Aucun graphique / chart** sur le dashboard (que du texte et des chiffres)
- **Aucune carte avec fond coloré** (tout est `surface` = blanc)
- **AppBar sans couleur** (un `GradientAppBar` existe dans le code mais n'est jamais utilisé)
- **Aucun gradient** visible dans l'UI
- **`FrostedCard.accentColor`** ne colore que le ripple au tap — aucun effet au repos
- **Aucune bordure colorée** sur les cartes
- **Aucun header de section coloré**
- **Aucun avatar coloré** (BeneficiaryAvatar = `primaryContainer` très pâle)
- **Material 3 `fromSeed()`** génère des surfaces très désaturées par défaut

## Conclusion

Changer la seed color (bleu → cyan, violet, etc.) n'aura **aucun impact perceptible** sur la sensation "fade" car la couleur n'est utilisée que sur du texte et des micro-accents à opacité très faible.

Le problème est structurel : le design system Frosted UI applique `colorScheme.surface` (blanc) sur **toutes les surfaces**, créant une UI monochrome blanche.

## Axes d'amélioration

1. **Dashboard** : ajouter des charts (pie chart catégories, bar chart mensuel)
2. **Cartes sommaires** : fond avec gradient léger de la couleur primaire au lieu de blanc
3. **AppBar** : utiliser le `GradientAppBar` existant ou teinter le `FrostedAppBar`
4. **FrostedCard** : exploiter `accentColor` pour une bordure ou un liseré latéral coloré au repos
5. **Cercles d'icônes** : passer de 10% à 20-30% d'opacité pour les rendre visibles
6. **Badges** : passer de 8-10% à 15-20% d'opacité
7. **Bottom nav** : icône active avec fond coloré (pill shape M3)
