# Dashboard Flow

## Principe

100% auto-computed. Zéro input user sauf la navigation de mois.

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
