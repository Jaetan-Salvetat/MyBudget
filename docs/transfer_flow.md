# Transfer Flow

## Principe

100% form structuré. Un virement est un mouvement entre 2 comptes de l'user — pas d'inférence possible.

## Création

Form avec :
- Compte source (picker, pré-sélectionné = dernier utilisé)
- Compte destination (picker, pré-sélectionné = most-used avec ce compte source)
- Montant
- Date
- Libellé (optionnel)

## Automatisations

| Tâche | Layer | Méthode |
|---|---|---|
| Compte source par défaut | 1 | Prefs : dernier utilisé |
| Compte destination par défaut | 1 | Prefs : paire la plus fréquente |
| Date | 0 | Aujourd'hui par défaut |

## Pourquoi pas de LLM

- Un virement nécessite 2 comptes explicites
- L'app ne peut pas deviner entre quels comptes l'user veut transférer
- Fréquence faible (~1/mois)
- 3 taps suffisent (source, destination, montant)

## Lien avec Quick-Add

Si l'user tape "virement 500€" dans le quick-add, redirection vers le form transfer avec montant pré-rempli.

```
Quick-add: "virement 500€ vers livret"
  │
  ▼
CamemBERT: semantic_tags = ["virement", "transfert", "bancaire"]
  │
  ▼
Détection: type = transfer → redirection vers form
  │
  ▼
Form Transfer ouvert avec amount = 500 pré-rempli
Fuzzy match "livret" → compte "Livret A" pré-sélectionné en destination
```
