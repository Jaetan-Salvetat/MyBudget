# MyBudget

MyBudget est une application de gestion de finances personnelles développée en **Flutter**. Elle permet aux utilisateurs de suivre leurs comptes, dépenses, revenus et emprunts dans une interface moderne utilisant un design "Glassmorphism" (Frosted UI).

L'application est conçue pour être **local-first** (données stockées localement) et met l'accent sur la confidentialité et la fluidité de l'expérience utilisateur.

## 🚀 Installation & Démarrage

1.  **Prérequis**: Flutter SDK ^3.7.2
2.  **Cloner le projet**:
    ```bash
    git clone https://github.com/Jaetan-Salvetat/MyBudget.git
    cd MyBudget
    ```
3.  **Installer les dépendances**:
    ```bash
    flutter pub get
    ```
4.  **Lancer l'application**:
    ```bash
    flutter run
    ```

---

## 📚 Documentation Technique

### 1. Stack Technique

#### Core
*   **Framework**: Flutter (SDK ^3.7.2)
*   **Langage**: Dart

#### Architecture & État
*   **Architecture**: MVVM (Model-View-ViewModel) avec Repository Pattern.
*   **State Management**: `provider` (^6.1.1). Utilisation de `MultiProvider` à la racine pour l'injection de dépendances.

#### Données & Stockage
*   **Base de données**: `objectbox` (^4.2.0). Base de données NoSQL haute performance pour le stockage local.
*   **Préférences**: `shared_preferences` (^2.2.2) pour les réglages simples (thème, langue, etc.).

#### UI & Design
*   **Design System**: `frosted_ui` (Librairie personnalisée).
*   **Icônes**: `cupertino_icons`, `flutter_svg`.

### 2. Architecture du Projet

Le projet suit une structure claire séparant la logique métier, les données et l'interface utilisateur.

#### Structure des Dossiers (`lib/`)
*   `core/`: Composants transversaux.
    *   `repositories/`: Couche d'abstraction pour l'accès aux données.
    *   `services/`: Services globaux (ObjectBox, Preferences).
    *   `theme/`: Thème de l'application (`AppTheme`).
    *   `constants/`, `enums/`, `errors/`: Définitions communes.
*   `models/`: Modèles de données (Entités ObjectBox).
*   `ui/`: Écrans et Widgets.
    *   Organisé par fonctionnalité (`home`, `dashboard`, `accounts`, `expenses`, etc.).
    *   Chaque dossier contient généralement les écrans (`_screen.dart`), les ViewModels (`_viewmodel.dart`) et les widgets spécifiques.
*   `utils/`: Fonctions utilitaires.
*   `main.dart`: Point d'entrée. Initialise les services et configure les Providers.

### 3. Modèles de Données (Data Layer)

Les modèles sont annotés avec `@Entity` pour ObjectBox.

*   **AccountModel**: Compte bancaire (Nom, Banque).
*   **ExpenseModel**: Dépense (Montant, Catégorie, Date, Fréquence, Compte).
*   **RevenueModel**: Revenu (Montant, Date, Régularité, Compte).
*   **LoanModel**: Emprunt (Montant, Prêteur, Mensualité, Dates, Statut).
*   **CategoryModel**: Catégorie de dépense (Nom, Icône, Couleur).

### 4. Gestion de l'État (State Management)

L'application utilise `Provider` pour injecter les dépendances et gérer l'état.

#### Flux de Données
1.  **ObjectBoxService**: Initialise la base de données.
2.  **Repositories**: (Ex: `AccountRepository`) Enveloppent les `Box<T>` d'ObjectBox pour fournir des méthodes CRUD.
3.  **ViewModels**: (Ex: `AccountViewModel`)
    *   Consomment les Repositories.
    *   Exposent les données (Listes, Totaux) à l'UI.
    *   Notifient l'UI des changements via `notifyListeners()`.
4.  **UI**: Consomme les ViewModels via `Consumer` ou `context.watch/read`.

### 5. Interface Utilisateur (UI)

#### Navigation
*   **HomeScreen**: Écran principal avec une barre de navigation inférieure (`FrostedBottomNavigationBar`).
*   **Tabs**: Dashboard, Comptes, Dépenses, Revenus, Emprunts.
*   **Modales**: Utilisation intensive de `BottomSheet` pour la création/édition.

#### Design System (Frosted UI)
L'application utilise une esthétique "verre givré" personnalisée.
*   `FrostedScaffold`: Fond d'écran avec effet de flou.
*   `FrostedAppBar`: Barre d'application translucide.
*   `FrostedGlassContainer`: Conteneur de base pour les cartes.
*   `FrostedTextField`, `FrostedButton`: Composants de formulaire stylisés.

### 6. Gestion des Dates

*   **Stockage**: `DateTime` (ObjectBox).
*   **Locale**: 'fr_FR' (initialisé dans `main.dart`).
*   **Formatage**: Utilisation de `DateFormat` (package `intl`) et d'une extension personnalisée `DateExtension` (`lib/utils/extensions.dart`).
*   **Règle**: L'année est ignorée.
    *   **Mensuel** : Seul le **jour** compte.
    *   **Annuel** : Le couple **jour + mois** compte.

### 7. Services Clés

*   **ObjectBoxService** (`core/services/objectbox_service.dart`): Singleton qui gère l'ouverture et la fermeture du `Store` ObjectBox.
*   **PreferencesService** (`core/services/preferences_service.dart`): Wrapper autour de `SharedPreferences` pour les réglages utilisateur.
