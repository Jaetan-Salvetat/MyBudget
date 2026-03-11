# Audit couleur — MyBudget

## Contexte

Retour utilisateur : "l'app est trop fade en terme de couleur."

## Diagnostic

Le problème **n'est pas la couleur choisie** (`#1565C0` — bleu saturé correct), mais le fait que **l'app n'utilise quasiment pas de couleur**.

## Surfaces (100% de la surface visible)

| Composant | Couleur actuelle | Résultat visuel |
|---|---|---|
| FrostedCard | `colorScheme.surface` (solide) | Blanc |
| FrostedAppBar | `surface` à 70% alpha + blur | Blanc translucide |
| FrostedBottomNavigationBar | `surface` à 70% alpha + blur | Blanc translucide |
| FrostedBottomSheet | `surface` à 70% alpha + blur | Blanc translucide |
| FrostedDialog | `surface` à 70% alpha + blur | Blanc translucide |
| Scaffold background | Default M3 | Blanc/gris très clair |
| FAB | `primaryContainer` M3 | Bleu très désaturé |

**Résultat** : l'UI entière est un bloc blanc uniforme.

## Accents colorés (seuls éléments non-blancs)

| Élément | Couleur | Opacité | Visibilité |
|---|---|---|---|
| Montants revenus | `colorScheme.primary` | 100% | Visible (texte seul) |
| Montants dépenses | `colorScheme.error` | 100% | Visible (texte seul) |
| Cercles icônes catégories | `category.color` | 15% | Quasi invisible |
| Badges montants | `primary` / `error` | 8-10% | Quasi invisible |
| Sub-cards (mensuel/annuel) | `primary` / `error` | 8% | Quasi invisible |
| Progress bars catégories | `category.color` | 100% | Visible |
| Progress bars emprunts | `primary` | 100% | Visible (4px ou 12px) |
| Icônes settings | `primary` | 20% | Faible |
| Statut emprunts | `amber` / `blue` / `green` | 100% | Visible (petit badge) |
| Section emprunts dashboard | `secondary` | 8% | Quasi invisible |

## Contraintes frosted_ui (v0.0.5)

Analyse du package source — voici ce qui est **paramétrable** et ce qui ne l'est **pas** :

| Composant | backgroundColor param ? | Gradient ? | Autre couleur ? |
|---|---|---|---|
| FrostedScaffold | Oui | Non | `drawerScrimColor` |
| FrostedAppBar | **Non** (hardcodé `surface@0.7`) | Non | `blurStrength` seulement |
| FrostedCard | **Non** (hardcodé `surface`) | Non | `accentColor` = ripple uniquement |
| FrostedBottomSheet | **Non** (hardcodé `surface@0.7`) | Non | `blurStrength` seulement |
| FrostedBottomNavigationBar | **Non** (hardcodé `surface@0.7`) | Non | `blurStrength` seulement |
| FrostedDialog | **Oui** | Non | `blurStrength` |
| FrostedSliverAppBar | **Oui** | Non | `blurStrength` |
| FrostedSnackbar | **Oui** | Non | `textColor` |
| FrostedButton (all) | **Oui** | Non | `foregroundColor` |
| FrostedTextField | Non | Non | `accentColor` (border focus) |

**Conclusion frosted_ui** : Les 3 composants les plus visibles (AppBar, Card, BottomNav) n'ont **aucun paramètre de couleur de fond**. Toute amélioration colorée sur ces surfaces nécessite soit :
- une mise à jour du package frosted_ui (ajout de `backgroundColor` params)
- un wrapping custom (Container avec couleur autour du composant)
- le remplacement par un widget custom

## GradientAppBar existant (non utilisé)

`lib/ui/common/widgets/gradient_app_bar.dart` existe déjà dans le code :
- Gradient linéaire `primary` → `primaryContainer` (topLeft → bottomRight)
- Texte `onPrimary`
- Shadow `black@0.1`
- **N'est utilisé nulle part** dans l'app (tous les écrans utilisent `FrostedAppBar`)

## Échelle d'opacité actuelle

| Opacité | Usage | Rendu |
|---|---|---|
| 0.08 | Sub-cards colorées (mensuel/annuel) | Quasiment blanc |
| 0.1 | Badges, cercles icônes | À peine perceptible |
| 0.15 | Cercles icônes catégories (expense cards) | Faible |
| 0.2 | Progress bar bg, icônes settings | Léger |
| 0.4-0.6 | Textes secondaires | Grisé |
| 0.7-0.8 | Labels dans sections colorées | Lisible |
| 1.0 | Montants, progress bars | Plein |

Les backgrounds colorés (0.08-0.15) sont **en dessous du seuil de perception** sur écran standard, surtout en mode clair.

## Ce qui manque

- **Aucun graphique / chart** sur le dashboard (que du texte et des chiffres)
- **Aucune carte avec fond coloré** — tout est `surface` = blanc
- **AppBar sans couleur** — `GradientAppBar` existe mais n'est jamais utilisé
- **Aucun gradient** visible dans l'UI
- **`FrostedCard.accentColor`** ne colore que le ripple au tap — aucun effet au repos
- **Aucune bordure colorée** sur les cartes
- **Aucun header de section coloré**
- **BeneficiaryAvatar** = `primaryContainer` très pâle M3
- **Material 3 `fromSeed()`** génère des surfaces très désaturées par défaut
- **Couleurs hardcodées** : upcoming payments utilise `Colors.green`/`Colors.blueGrey`, appearance section utilise `Colors.grey`

## Conclusion

Changer la seed color n'aura **aucun impact perceptible** car la couleur n'est utilisée que sur du texte et des micro-accents à opacité très faible (0.08-0.15).

Le problème est **structurel à deux niveaux** :
1. **frosted_ui** impose `surface` blanc sur AppBar, Card et BottomNav sans override possible
2. **L'app** utilise des opacités trop basses (0.08-0.1) sur les rares éléments colorés

---

## Décisions

- **frosted_ui** : on n'y touche pas
- **Ton** : app finance = sobre et professionnel, pas multicolore
- **GradientAppBar** : à supprimer (vestige d'avant la refonte visuelle)

## Plan d'amélioration retenu

### 1. Remonter les opacités (quick win)

Les backgrounds colorés actuels (0.08-0.15) sont sous le seuil de perception. Nouvelles valeurs :

| Élément | Avant | Après |
|---|---|---|
| Sub-cards (mensuel/annuel) | 0.08 | 0.15 |
| Badges montants | 0.08-0.1 | 0.18 |
| Cercles icônes catégories | 0.15 | 0.25 |
| Section emprunts dashboard | 0.08 | 0.15 |
| Icônes settings | 0.2 | 0.3 |
| Cercles icônes (revenus, emprunts) | 0.1 | 0.2 |

### 2. Liséré coloré sur cartes (quick win)

Ajouter un left border coloré sur les cartes :
- Si la carte a une catégorie : couleur de la catégorie
- Sinon : `primary` ou `primaryContainer`
- Épaisseur : ~3px, borderRadius assorti

### 3. Supprimer GradientAppBar (nettoyage)

Supprimer `lib/ui/common/widgets/gradient_app_bar.dart` — vestige non utilisé.

### 4. Charts dashboard (feature principale)

- **Pie chart** : répartition des dépenses par catégorie (couleurs des catégories)
- **Bar chart** : revenus vs dépenses par mois

Package recommandé : `fl_chart` (léger, customisable, pas de dépendance native).
