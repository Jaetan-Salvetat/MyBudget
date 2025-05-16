# Composants UI réutilisables - MyBudget

## Composants communs existants
- [x] GradientAppBar - Barre d'application avec dégradé
- [x] GradientSliverAppBar - Version Sliver de la barre d'application avec dégradé
- [x] AppScaffold - Structure de base pour les écrans avec navigation
- [x] FinancialCard - Carte pour afficher des informations financières
- [x] SectionHeader - En-tête de section réutilisable
- [x] AppTextField - Champ de texte personnalisé
- [x] AppDropdownField - Liste déroulante personnalisée
- [x] AppDatePicker - Sélecteur de date personnalisé
- [x] FilterChip - Composant de filtre réutilisable
- [x] ModalBottomSheet - Feuille modale de bas d'écran

## Composants à extraire

### Éléments d'interface
- [ ] Carte de résumé financière - Extraire `SummaryCards` en composant générique
- [ ] Boîte de dialogue de filtrage et tri - Extraire `_showFilterAndSortOptions` en composant réutilisable
- [ ] Widget d'état vide - Généraliser `EmptyAccountsState` en composant configurable
- [ ] Carte de liste d'élément - Template réutilisable pour tous les types d'éléments
- [ ] Boîte de dialogue de confirmation de suppression - Extraction du pattern dans `_deleteAccount`
- [ ] Badge de statut - Pour afficher des statuts comme "actif/inactif" ou "payé/en attente"
- [ ] Barre d'actions contextuelles - Pour modifier/supprimer/partager des éléments
- [ ] Entête de détail avec avatar/icône - Pour les écrans de détail avec icône, titre et sous-titre
- [ ] Menu d'options trois points - Menu contextuel standardisé
- [ ] Curseur de sélection de période - Pour sélectionner des plages de dates
- [ ] Indicateurs de tendance - Widgets avec flèches vers le haut/bas et pourcentages
- [ ] Barres de progression - Pour visualiser les objectifs financiers
- [ ] Grille de statistiques - Pour afficher plusieurs métriques ou statistiques
- [ ] Sélecteur de catégorie avec icônes - Pour choisir une catégorie avec icônes colorées
- [ ] Widget de pagination - Pour naviguer entre les pages de résultats
- [ ] Toast de notification - Pour afficher des messages de confirmation ou d'erreur
- [ ] Bouton d'action flottant avec menu - FAB extensible avec options
- [ ] En-tête de section avec toggle - Pour réduire/développer une section
- [ ] Graphiques réutilisables - Visualisations de données standardisées
- [ ] Sélecteur de comptes - Pour choisir facilement un compte

### Sections de page réutilisables
- [ ] FilterAndSortSection - Section pour filtrer et trier les données
- [ ] EmptyStateSection - Section d'état vide avec message et illustration
- [ ] StatisticsSection - Section pour afficher des statistiques
- [ ] ActionButtonsSection - Section de boutons d'action (modifier, supprimer, partager)
- [ ] TransactionListSection - Section de liste de transactions
- [ ] AccountSummarySection - Section de résumé des comptes avec solde total
- [ ] CategoryBreakdownSection - Section de répartition par catégorie

### Comportements réutilisables
- [x] BouncingScrollPhysics - Appliqué à tous les éléments défilables pour un comportement cohérent
- [ ] SwipeActionBehavior - Comportement de glissement pour effectuer des actions sur les éléments de liste
- [ ] ItemSelectionBehavior - Comportement de sélection d'éléments dans les listes

## Avantages de l'extraction des composants
- Meilleure maintenance du code
- Cohérence de l'interface utilisateur
- Réduction de la duplication de code
- Facilitation du développement de nouvelles fonctionnalités
- Respect des principes SOLID
