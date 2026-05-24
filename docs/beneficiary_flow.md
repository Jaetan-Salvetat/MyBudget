# Beneficiary Flow

## Principe

Les bénéficiaires sont **extraits** automatiquement depuis le quick-add mais **jamais auto-créés**. L'user confirme toujours.

## Extraction (via CamemBERT)

CamemBERT extrait un `beneficiary_hint` par NER entité personne.

```
"filé par Marie 200€"    → beneficiary_hint = "Marie"
"remboursé Pierre 50€"   → beneficiary_hint = "Pierre"
"loyer 800€"             → beneficiary_hint = null
```

## Matching (via fuzzy)

```
beneficiary_hint = "Marie"
  │
  ▼
[FUZZY] vs bénéficiaires existants dans ObjectBox
  │
  ├─ "Marie Dupont" (score 0.92) → proposer sur la carte
  ├─ "Marie L." (score 0.88)     → proposer aussi si >1 match
  └─ Aucun match                 → ignorer, pas de suggestion
```

## UX sur la carte de confirmation

### Match trouvé

```
╭──────────────────────────────╮
│  Remboursement    +200,00 €  │
│  Revenu · Ponctuel           │
│  💰 Revenus                  │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  │
│  👤 Marie Dupont ?      [✓]  │
╰──────────────────────────────╯
```

1 tap sur [✓] → associe le bénéficiaire. Tap sur le nom → picker. Ignorer → pas de bénéficiaire.

### Aucun match

Pas de ligne bénéficiaire affichée. L'user peut l'ajouter manuellement via le form complet s'il le souhaite.

## Création manuelle

Uniquement via Settings > Bénéficiaires ou via le form complet d'une transaction. Jamais automatique.

Champs :
- Nom (obligatoire)
- Notes (optionnel)

## Pourquoi pas d'auto-création

- Un hint NER peut être faux ("chez Marie" = restaurant, pas une personne)
- Pollution de la liste avec des faux positifs
- Le coût d'un tap de confirmation est négligeable vs le coût de cleanup
