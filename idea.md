- Manage payments between accounts
- Account.type (saving, tracking, etc)
- notifications, what type of notification?
- Expense.isActivated (activate or desavtivate an expense). same for loans
- Two type of usage: sample and full

---

## 🎯 Plan d'amélioration UX/UI (2026-01-12)

Suite à l'analyse complète de l'app, voici les actions prioritaires :

### 3. Repenser Dashboard
- **Action** : Revoir la structure du dashboard (garder le header, repenser le reste)
- **Points à adresser** :
  - Section "Paiements à venir" : scroll horizontal = UX discutable
  - Section "Dépenses par catégorie" : ajouter un vrai graphique (pie chart)
  - Hiérarchie visuelle : mettre plus en valeur le Reste à Vivre
- **Fichiers concernés** :
  - `lib/ui/dashboard/dashboard_screen.dart`
  - `lib/ui/dashboard/widgets/upcoming_payments_card.dart`
  - `lib/ui/dashboard/widgets/category_summary_card.dart`
- **Note** : Nécessite brainstorming sur la nouvelle structure avant implémentation

### 5. Suppression Section "Financial Calculations"
- **Action** : Supprimer l'option "Calcul des dépenses annuelles" des settings
- **Rationale** : Option trop technique et obscure pour l'utilisateur lambda
- **Impact** : Simplification des settings, réduction de la complexité
- **Fichiers concernés** :
  - `lib/ui/settings/widgets/sections/financial_calculations_section.dart` (supprimer complètement)
  - `lib/ui/settings/settings_screen.dart` (retirer l'import et l'affichage de la section)
  - `lib/ui/settings/widgets/expense_calculation_bottom_sheet.dart` (supprimer)
  - `lib/ui/settings/settings_viewmodel.dart` (supprimer `annualExpenseCalculationMode`)
  - `lib/core/services/preferences_service.dart` (supprimer clé associée)
  - **IMPORTANT** : Vérifier tous les endroits où `annualExpenseCalculationMode` est utilisé
    - `lib/ui/dashboard/dashboard_viewmodel.dart` (lignes 41, 44, 51)
    - `lib/ui/expenses/expenses_viewmodel.dart`
- **Décision à prendre** : Garder quel comportement par défaut ? (Amortissement mensuel ou Mois spécifique)

### 6. Gestion des Suppressions en Cascade
- **Action** : Définir et implémenter une stratégie pour les suppressions
- **Cas à gérer** :
  1. **Suppression d'un compte** → que deviennent les dépenses/revenus/prêts associés ?
  2. **Suppression d'une catégorie** → que deviennent les dépenses de cette catégorie ?
- **Options possibles** :
  - **Option A** : Bloquer la suppression si éléments associés
    - Message : "Impossible de supprimer ce compte, 3 dépenses y sont associées"
    - UX : Sécurisé mais peut frustrer l'utilisateur
  - **Option B** : Supprimer en cascade avec confirmation
    - Message : "⚠️ Attention : 3 dépenses, 2 revenus et 1 prêt seront supprimés. Continuer ?"
    - UX : Dangereux mais flexible
  - **Option C** : Réassigner à un compte/catégorie par défaut
    - Créer un compte "Sans compte" et une catégorie "Sans catégorie"
    - UX : Pas de perte de données mais peut créer du bazar
- **Décision à prendre** : Quelle option choisir ?
- **Fichiers concernés** :
  - `lib/ui/accounts/accounts_viewmodel.dart` (méthode `deleteAccount`)
  - `lib/ui/settings/category_viewmodel.dart` (méthode pour suppression catégorie)
  - Potentiellement les repositories pour cascade SQL/ObjectBox

### 7. Edge Case : Paiements le 31
- **Action** : Définir le comportement pour les dépenses mensuelles au 31
- **Problème** : Certains mois n'ont pas 31 jours (février = 28/29, avril/juin/septembre/novembre = 30)
- **Options possibles** :
  - **Option A** : Décaler automatiquement au dernier jour du mois
    - 31 en février → 28 (ou 29 si bissextile)
    - 31 en avril → 30
    - UX : Transparent mais peut être trompeur
  - **Option B** : Bloquer la saisie du 31 avec message d'avertissement
    - Message : "⚠️ Le 31 n'existe pas dans tous les mois. Choisissez un jour entre 1 et 28."
    - UX : Sécurisé mais restrictif
  - **Option C** : Permettre mais afficher un warning
    - Warning dans le formulaire : "ℹ️ Attention : le 31 n'existe pas dans tous les mois"
    - UX : Informe l'utilisateur sans bloquer
  - **Option D** : Documenter le comportement actuel
    - Ajouter une note dans l'UI expliquant ce qui se passe
- **Décision à prendre** : Quelle option préférer ?
- **Fichiers concernés** :
  - `lib/ui/common/widgets/frosted_date_selector.dart` (si validation/warning)
  - `lib/ui/expenses/widgets/expense_bottom_sheet.dart` (validation)
  - `lib/utils/extensions.dart` (si logique de décalage automatique)
  - Documentation à ajouter dans CLAUDE.md