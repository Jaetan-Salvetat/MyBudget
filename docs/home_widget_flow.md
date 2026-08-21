# Home Widget Flow

## Principe

Widget Android/iOS sur l'écran d'accueil. Affiche le solde et les dépenses du mois. 100% automatique.

## Layers

| Tâche | Layer | Méthode |
|---|---|---|
| Affichage données | 0 | Auto-refresh sur data change |
| Refresh | 0 | Déclenché par toute modification de transaction/compte |
| Configuration | 0 | Aucune — affiche le compte par défaut |

## Données affichées

- Solde du compte principal
- Dépenses du mois en cours
- Balance (revenus - dépenses)

## Refresh

```
Transaction ajoutée/modifiée/supprimée
  │
  ▼
[ALGO] Recalcul solde + dépenses mois
  │
  ▼
Widget mis à jour
```

Pas de polling. Event-driven via le data layer.

## Pas de LLM

Agrégation numérique pure.
