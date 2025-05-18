# Composants réutilisables à extraire

## Composants UI

- [x] **FinancialSummaryCard** - Carte de résumé financier avec indicateur de tendance et solde
  - Utilisé dans: AccountsScreen, ExpensesScreen, RevenuesScreen, LoansScreen
  - Contient: Titre, Icône, Montant avec formatage, Indicateur de tendance

- [x] **DeleteConfirmationDialog** - Dialogue de confirmation de suppression
  - Utilisé dans: AccountsScreen, ExpensesScreen, RevenuesScreen, LoansScreen
  - Permet de standardiser les dialogues de confirmation

- [x] **ErrorDialog** - Dialogue d'erreur (ex: _showCannotDeleteDialog)
  - Utilisé dans: AccountsScreen

- [x] **EmptyStateView** - Affichage d'état vide configurable
  - Utilisé dans: AccountsList, ExpensesList, RevenuesList, LoansList

- [ ] **CategoryIconMapper** - Utilitaire pour mapper types/catégories aux icônes
  - Utilisé dans: AccountListCard._getIconForBank, ExpenseCard._getCategoryIcon

- [ ] **ActionButtonsRow** - Rangée de boutons d'actions (modifier, supprimer)
  - Utilisé dans: ExpenseCard, RevenueCard

## Comportements

- [ ] **BouncingScrollBehavior** - Wrapper pour appliquer BouncingScrollPhysics
  - À appliquer sur tous les éléments défilables conformément aux exigences

## Utilités

- [ ] **CurrencyFormatter** - Formatage des montants en devise
  - Utilisé dans plusieurs endroits pour formater les montants

- [ ] **DateFormatter** - Formatage des dates selon différents patterns
  - Utilisé dans ExpenseCard._formatDate et RevenueCard

## Directive d'implémentation

- Respecter les principes SOLID
- Ne pas utiliser de points-virgules en JavaScript/TypeScript
- Ne pas inclure de commentaires dans le code
- Standardiser l'application de BouncingScrollPhysics
