# Dashboard Flow

## Principe

100% auto-computed. Zéro input user sauf la navigation de mois et le champ
d'ajout rapide.

## Ordre des sections

Salutation · sélecteur de mois · solde · **champ quick-add** · répartition ·
à venir · emprunts.

Le champ est sous le solde, pas au-dessus : on lit ce qu'il reste avant de
saisir. Au focus, `DashboardHeaderBalance` remplace la hero card par
`CompactBalanceLine` (le solde doit rester lisible au-dessus du clavier) et « à venir » / « emprunts » se
replient. La répartition reste : c'est la section qui bouge visiblement quand
la transaction est enregistrée — et dès que le modèle a rendu une catégorie,
elle cède la place aux candidats à corriger (`QuickAddCategoryZone`).

## Bascule du header : hauteur seulement

`DashboardHeaderBalance` anime la hauteur, jamais l'opacité. Deux raisons :

- La hero card est en glass. Un `BackdropFilter` pris dans un calque d'opacité
  échantillonne ce calque au lieu de l'écran : il peint un bloc gris translucide
  sur la carte pendant toute la transition.
- Les deux mises en page portent le même chiffre. Les croiser l'imprime deux
  fois, dans deux typographies décalées de quelques pixels.

Les sections du bas peuvent, elles, garder un `AnimatedCrossFade` : elles sont
en `SolidCard` opaque et leur contre-partie est vide.

## Composants

| Composant | Layer | Méthode |
|---|---|---|
| Solde total | 0 | Somme des soldes de tous les comptes |
| Dépenses du mois | 0 | Somme des expenses du mois courant |
| Revenus du mois | 0 | Somme des revenues du mois courant |
| Balance mensuelle | 0 | Revenus - Dépenses |
| Répartition par catégorie | 0 | Group by category + somme |
| Budget health | 0 | Ratio dépenses/revenus → indicateur couleur |
| Navigation de mois | 3 | Manuel (tap arrows) |

## Alertes automatiques

| Alerte | Condition | Action |
|---|---|---|
| Overspend | Dépenses > Revenus du mois | Push notification + badge rouge |
| Catégorie en hausse | Dépense catégorie > 120% du mois précédent | Indicateur sur la catégorie |
| Prêt en retard | Paiement scheduled non enregistré | Notification |

Les alertes sont calculées en background à chaque nouvelle transaction. Pas de polling.

## Refresh

Le dashboard se recalcule automatiquement quand :
- Une transaction est ajoutée/modifiée/supprimée
- Un virement est effectué
- Un paiement de prêt est enregistré

Pas de pull-to-refresh nécessaire. Riverpod `ref.watch` sur les providers de données.

## Navigation de mois

Reste 100% manuelle. L'user tap les flèches gauche/droite pour naviguer dans l'historique. Pas d'automatisation possible (intention user pure).
