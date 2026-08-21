# Account Flow

## Principe

Création manuelle (1x par compte). L'app ne peut pas connaître les comptes bancaires de l'user offline.

## Création

Form avec :
- Nom du compte (libre)
- Nom de la banque (autocomplete)
- Solde initial
- Type (courant, épargne, commun)

## Automatisations

| Tâche | Layer | Méthode |
|---|---|---|
| Nom de banque | 2 | Autocomplete : liste ~30 banques françaises courantes |
| Compte par défaut | 0 | Prefs : last used = new default |
| Solde actuel | 0 | Algo : solde initial + somme(revenus) - somme(dépenses) - somme(virements sortants) + somme(virements entrants) |

## Autocomplete banques

Dataset statique embarqué dans l'app :

```
BNP Paribas, Société Générale, Crédit Agricole, LCL,
Crédit Mutuel, Banque Populaire, Caisse d'Épargne,
La Banque Postale, Boursorama, Fortuneo, Hello bank!,
N26, Revolut, Monabanq, ING, HSBC, AXA Banque, ...
```

i18n : adapter la liste par locale si expansion future.

## Compte par défaut

```
User crée une dépense sur "Compte Courant BNP"
  │
  ▼
[PREFS] defaultAccount = "Compte Courant BNP"
  │
  ▼
Prochain quick-add → account pré-sélectionné = "Compte Courant BNP"
```

L'user peut swap en 1 tap sur la carte de confirmation.

## Onboarding

Premier lancement : l'app demande de créer **un** compte avant le premier quick-add. C'est le seul form obligatoire du onboarding.

```
Install → "Quel est ton compte principal ?"
  │
  ▼
Form minimal : nom + banque (autocomplete) + solde initial
  │
  ▼
Quick-add disponible
```
