# Receipt Scan Flow

## Principe

Scan d'un ticket de caisse → extraction des items → même pipeline quick-add. Feature future, pas dans le scope du sprint initial.

## Pipeline

```
User prend une photo / sélectionne une image
  │
  ▼
[LLM Vision] Gemma (ou modèle vision dédié)
  → merchant, items[], total, date
  │
  ▼
[ALGO] Vérification total = somme(items)
  │
  ▼
Pour chaque item:
  │
  ▼
[MEMORY] Merchant connu ? (>95% accuracy historique)
  ├─ OUI → auto-save, skip confirmation
  └─ NON → review card (1 tap confirm par item)
```

## Output LLM Vision

```json
{
  "merchant": "Carrefour",
  "date": "2026-05-22",
  "items": [
    { "name": "Lait", "amount": 1.29 },
    { "name": "Pain", "amount": 0.99 },
    { "name": "Bière", "amount": 3.50 }
  ],
  "total": 5.78
}
```

## Merchant connu vs inconnu

| Scénario | Condition | Action | Layer |
|---|---|---|---|
| Merchant connu | >95% accuracy sur les 10 derniers scans de ce merchant | Auto-save toutes les lignes | 0 |
| Merchant inconnu | Nouveau ou <95% accuracy | Review card avec items modifiables | 1 |

## Catégorisation par item

Chaque item passe dans le pipeline catégorie standard :

```
Item: "Bière 3.50€"
  │
  ▼
[MEMORY] "bière" → "Courses" ? → HIT → auto
  │
  ▼ si MISS
[CamemBERT] tags = ["boisson", "alcool", "alimentaire"]
  │
  ▼
[Gemma] → "Courses"
```

## Lien avec Quick-Add

Le receipt scan ne remplace pas le quick-add. Il l'alimente.

```
Scan → items extraits → chaque item = un quick-add pré-rempli → même carte de confirmation
```

## Scope

- V1 : pas dans le sprint initial
- V2 : scan basique (1 receipt = 1 merchant = 1 catégorie globale)
- V3 : scan détaillé (multi-items, catégorisation par ligne)
