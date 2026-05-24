# Auto-Update Flow

## Principe

Détection automatique + notification. Déjà implémenté via `UpdateNotifier` + `GithubService`.

## Pipeline

```
App launch
  │
  ▼ (background)
[ALGO] Poll GitHub releases API
  │
  ▼
Comparer version locale vs dernière release
  │
  ├─ Même version → rien
  └─ Nouvelle version disponible
       │
       ▼
       Notification in-app : "Mise à jour disponible"
       │
       ▼
       1 tap → ouvrir lien téléchargement
```

## Layers

| Tâche | Layer | Méthode |
|---|---|---|
| Version check | 0 | Background polling |
| Notification | 0 | Auto-affichée |
| Téléchargement | 1 | 1 tap user |

## Version stripping

Beta versions : `RegExp(r'-beta(\.\d+)?')` pour comparer proprement.

## Pas de LLM

Comparaison de versions = string comparison. Aucune inférence nécessaire.
