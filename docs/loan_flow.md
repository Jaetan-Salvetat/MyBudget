# Loan Flow

## Principe

100% form structuré. Trop rare (1-5x/an) et trop critique (données légales/financières) pour justifier du LLM.

## Création

Form complet avec tous les champs obligatoires :
- Nom du prêt
- Montant emprunté
- Taux d'intérêt
- Durée (mois)
- Date de début
- Mensualité (auto-calculée ou saisie manuelle)
- Assurance (optionnel : taux, montant)
- Bénéficiaire (optionnel, picker)
- Compte source (picker)

## Automatisations (algo pur)

| Tâche | Layer | Méthode |
|---|---|---|
| Calcul mensualité | 0 | Formule amortissement standard |
| Tableau d'amortissement | 0 | Auto-généré depuis montant/taux/durée |
| Suivi des paiements | 0 | Auto-déduit mensuellement sur le schedule |
| Capital restant dû | 0 | Auto-computed à chaque paiement |
| Coût total du crédit | 0 | Somme des intérêts sur la durée |

## Pourquoi pas de LLM

- Les termes d'un prêt sont des données légales exactes
- Aucune inférence possible (taux, durée = contrat)
- Erreur d'arrondi sur un taux = impact financier réel
- Fréquence d'usage trop faible pour justifier l'optimisation

## Lien avec Quick-Add

Si l'user tape "prêt 200k" dans le quick-add, le système ne crée PAS de prêt. Il redirige vers le form loan avec le montant pré-rempli.

```
Quick-add: "prêt 200000€"
  │
  ▼
CamemBERT: semantic_tags = ["crédit", "emprunt", "prêt"]
  │
  ▼
Détection: type = loan → redirection vers form
  │
  ▼
Form Loan ouvert avec amount = 200000 pré-rempli
```
