# Import / Export Flow

## Export

| Aspect | Détail |
|---|---|
| Layer | 1 (1 tap) |
| Méthode | Algo — sérialisation JSON/CSV |
| Déclencheur | Settings > Exporter |
| Format | JSON (complet, reimportable) ou CSV (lisible) |
| Scope | Toutes les données : comptes, transactions, catégories, prêts, virements, bénéficiaires |

Pas de config : 1 tap → fichier généré → share sheet OS.

## Import

| Aspect | Détail |
|---|---|
| Layer | 2 (pick file + confirm) |
| Méthode | Algo — parsing + validation |
| Déclencheur | Settings > Importer |
| Format accepté | JSON (export MyBudget) |

### Pipeline import

```
User sélectionne un fichier
  │
  ▼
[ALGO] Parse JSON → validation schéma
  │
  ▼
[ALGO] Détection conflits (IDs existants)
  │
  ▼
Écran résumé : "X comptes, Y transactions, Z catégories"
  │
  ▼
User confirme → import
```

## Pas de LLM

L'import/export manipule des données structurées. Pas d'ambiguïté, pas de sémantique. Algo pur.
