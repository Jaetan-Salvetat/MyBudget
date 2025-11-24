# Plan de Tests - MyBudget

Ce document liste l'ensemble des fichiers et fonctionnalités à tester pour garantir la robustesse de l'application.

## 1. Tests Unitaires (Logique Métier & Données)

### Modèles (`lib/models/`)
Vérification de la logique interne, des méthodes calculées (getters) et des méthodes de copie/création.
- [x] `loan_model.dart`
  - Calculs financiers (`totalCost`, `remainingCapital`, `progress`, `isCompleted`).
  - Gestion des dates et durées.
- [ ] `account_model.dart`
  - Propriétés basiques.
- [x] `expense_model.dart`
  - Relations (categoryId, accountId).
- [ ] `revenue_model.dart`
  - Relations et types (ponctuel/régulier).
- [ ] `category_model.dart`

### Utilitaires (`lib/utils/`)
Fonctions pures et logiques de calcul critiques.
- [x] `loan_calculator.dart` (Si utilisé hors du modèle)
  - Formules d'amortissement.
  - Calcul des mensualités.
- [ ] `extensions.dart` (Si contient de la logique métier)

### ViewModels (`lib/ui/**/viewmodels/` & `lib/ui/**/*_viewmodel.dart`)
Test de la gestion d'état et de la logique métier (CRUD, Calculs agrégés).
*Nécessite le mock des Repositories.*

**Loans (Prêts)**
- [x] `loans_viewmodel.dart`
  - Calculs globaux (`getTotalActiveInitialAmount`, `getTotalRemainingCost`, etc.).
  - Filtrage (Actifs/Terminés).
- [ ] `loan_creation_viewmodel.dart`
  - Validation des étapes du formulaire.
  - Calculs en temps réel (mensualité estimée).

**Accounts (Comptes)**
- [x] `accounts_viewmodel.dart`
  - Calcul du solde global.
  - Gestion de la liste des comptes.

**Expenses (Dépenses)**
- [ ] `expenses_viewmodel.dart`
  - Filtrage par date/catégorie.
  - Calcul des totaux.

**Revenues (Revenus)**
- [ ] `revenues_viewmodel.dart`
  - Distinction Régulier/Ponctuel.
  - Calculs mensuels.

**Dashboard**
- [ ] `dashboard_viewmodel.dart`
  - Agrégation des données (Reste à vivre, Taux d'épargne).

**Settings & Data**
- [ ] `data_viewmodel.dart`
  - Logique d'import/export (Parsing JSON).
  - Reset des données.
- [ ] `category_viewmodel.dart`

## 2. Tests de Widgets (Composants UI Critiques)

### Loans (Prêts)
- [x] `loan_summary_card.dart`
  - Affichage des totaux.
  - Interaction bouton "Help" (Dialog).
- [ ] `loan_card.dart`
  - Affichage des données (Capital restant vs Amorti).
  - Barre de progression.
- [ ] `loan_progress_section.dart` (Détail)
  - Vérification des labels et valeurs calculées.

### Dashboard
- [ ] Widgets de graphiques (si existants et testables).
- [ ] Cartes récapitulatives (Reste à vivre).

### Formulaires (Création/Edition)
Vérification de la validation et de l'interaction.
- [ ] `LoanCreationBottomSheet` (ou équivalent)
- [ ] `ExpenseCreationBottomSheet`

## 3. Tests d'Intégration (Parcours Utilisateur)
*Optionnel dans un premier temps, à faire si la base est solide.*
- [ ] Scénario : Création complète d'un prêt.
- [ ] Scénario : Ajout d'une dépense et vérification de l'impact sur le solde.

---
**Note :** Cocher les cases au fur et à mesure de l'avancement en remplaçant `[ ]` par `[x]`.
