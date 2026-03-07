# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyBudget is a local-first personal finance management Flutter application. It uses ObjectBox for local data storage and follows an MVVM architecture with the Provider pattern for state management. The app features a "Glassmorphism" (Frosted UI) design system.

**Important concept**: MyBudget is a **static budget** app. It only tracks fixed, predictable income and expenses (rent, subscriptions, salary, loans, etc.). Variable/punctual spending (groceries, restaurants, impulse purchases) is intentionally out of scope. The goal is to give a clear picture of recurring financial commitments, not to track every transaction.

**Language**: French (fr_FR locale)
**Flutter SDK**: ^3.7.2

## Common Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run a specific test file
flutter test test/unit/viewmodels/expense_viewmodel_test.dart

# Lint/analyze code
flutter analyze

# Generate ObjectBox code (after model changes)
flutter pub run build_runner build
```

### Building
```bash
# Build for Android (production)
flutter build apk --flavor prod --release

# Build for Android (beta flavor)
flutter build apk --flavor beta --release

# Build for iOS
flutter build ios
```

## Architecture

### MVVM + Repository Pattern

The app follows a clear separation of concerns:

1. **Models** (`lib/models/`): ObjectBox entities annotated with `@Entity`
   - AccountModel, ExpenseModel, RevenueModel, LoanModel, CategoryModel
   - Each model has a `copyWith()`, `toJson()`, `fromJson()` method

2. **Repositories** (`lib/core/repositories/`): Thin wrappers around ObjectBox `Box<T>`
   - Provide CRUD operations: `getAll()`, `get(id)`, `add()`, `update()`, `delete()`, `deleteAll()`
   - Example: `ExpenseRepository`, `AccountRepository`

3. **Domain Entities** (`lib/core/domain/`): Facade pattern over models
   - `Loan`: wraps `LoanModel` + calculation services, exposes computed properties
   - `LoanPaymentBreakdown`: immutable value object for payment decomposition

4. **ViewModels** (`lib/ui/*/`): Extend `ChangeNotifier`
   - Consume repositories via dependency injection
   - Expose data and state to UI
   - Call `notifyListeners()` to trigger UI updates
   - Located alongside their respective screens

5. **UI** (`lib/ui/`): Organized by feature
   - Each feature has screens, ViewModels, and widgets
   - Uses `Consumer` or `context.watch/read` to access ViewModels

### Dependency Injection

All dependencies are wired in [lib/main.dart](lib/main.dart) using `MultiProvider`:
- Services (ObjectBoxService, PreferencesService) are initialized first
- Repositories are created from ObjectBox boxes
- ViewModels are provided as `ChangeNotifierProvider` or `ChangeNotifierProxyProvider`
- Complex dependencies use `ChangeNotifierProxyProvider4` (e.g., AccountViewModel depends on 4 other ViewModels)

**Provider order in main.dart:**
1. ObjectBoxService (value)
2. Repositories (5 repos)
3. Simple ViewModels: SettingsViewModel, UpdateViewModel, ThemeViewModel, CategoryViewModel, ExpenseViewModel, RevenueViewModel, LoanViewModel
4. Proxy ViewModels: AccountViewModel (depends on 3 ViewModels), DataViewModel, DashboardViewModel

### Data Flow

```
ObjectBoxService (initializes Store)
  → Repositories (wrap Box<T>)
  → ViewModels (business logic + state)
  → UI (renders data)

LoanModel (persisted) → LoanService.createLoan() → Loan (domain entity with computed logic)
```

## Key Technical Details

### ObjectBox Setup

- **Service**: [lib/core/services/objectbox_service.dart](lib/core/services/objectbox_service.dart)
- Singleton pattern with `getInstance()` and `resetInstance()` for tests
- Boxes: categoryBox, expenseBox, revenueBox, accountBox, loanBox
- Generated code in [lib/objectbox.g.dart](lib/objectbox.g.dart)
- Schema in [lib/objectbox-model.json](lib/objectbox-model.json)
- After modifying `@Entity` models, regenerate with: `flutter pub run build_runner build`

### Date Handling

- **Locale**: 'fr_FR' (initialized in main.dart with `initializeDateFormatting`)
- **Storage**: `DateTime` stored as ObjectBox `@Property()`
- **Formatting**: Custom `DateExtension` in [lib/utils/extensions.dart](lib/utils/extensions.dart)
- **Important Rule**: Year is ignored for recurring expenses
  - Monthly: Only day matters (e.g., every 15th)
  - Annual: Day + month matter (e.g., every Jan 15)

### Frequency System

See [lib/core/enums/frequency.dart](lib/core/enums/frequency.dart):
- `Frequency.monthly`: Recurring every month — label: "Mensuel"
- `Frequency.annual`: Recurring every year — label: "Annuel"
- Methods: `label` getter, `fromString(value)` factory

### Annual Expense Calculation Mode

Configurable via `SettingsViewModel` and `AnnualExpenseCalculationMode` enum:
- `monthlyAmortized`: annual expense ÷ 12, spread across all months
- `dateBasedOnly`: annual expense only shown in the month it occurs

### Enum Storage Pattern

Models use a consistent pattern for storing enums in ObjectBox:
- Enums are stored as **string IDs** (e.g., `repaymentTypeId`, `insuranceTypeId`)
- Dart getters/setters provide enum conversion for cleaner code
- Example in [lib/models/loan_model.dart](lib/models/loan_model.dart):
  ```dart
  String repaymentTypeId;  // Stored in DB

  LoanRepaymentType get repaymentType {
    return LoanRepaymentType.values.firstWhere(
      (e) => e.name == repaymentTypeId,
      orElse: () => LoanRepaymentType.amortizable,
    );
  }

  set repaymentType(LoanRepaymentType type) {
    repaymentTypeId = type.name;
  }
  ```
- This pattern ensures ObjectBox compatibility while maintaining type safety

### Custom Design System (Frosted UI)

**IMPORTANT**: Always use `frosted_ui` components instead of standard Flutter widgets:
- Use `FrostedScaffold` instead of `Scaffold`
- Use `FrostedAppBar` instead of `AppBar`
- Use `FrostedTextField` instead of `TextField`
- Use `FrostedButton` instead of `ElevatedButton`/`TextButton`
- Use `FrostedCard` for cards
- Use `FrostedBottomSheet` for bottom sheets
- Use `FrostedDialog` for dialogs
- Use `FrostedIconButton` for icon buttons
- Use `FrostedSnackbar` for notifications
- Use `FrostedLinearProgressIndicator` for progress bars

The package is imported from GitHub:
```dart
import 'package:frosted_ui/frosted_ui.dart';
```

Available components:
- `FrostedScaffold`, `FrostedAppBar`, `FrostedGlassContainer`
- `FrostedTextField`, `FrostedButton`, `FrostedTextButton`, `FrostedIconButton`
- `FrostedCard`, `FrostedBottomSheet`, `FrostedDialog`
- `FrostedBottomNavigationBar` for main navigation
- `FrostedDivider`, `FrostedLinearProgressIndicator`, `FrostedSnackbar`
- Inline validation with contextual error messages

### Navigation Structure

Main screen is [lib/ui/home/home_screen.dart](lib/ui/home/home_screen.dart) with bottom navigation:
1. Dashboard (index 0)
2. Accounts (index 1)
3. Expenses (index 2)
4. Revenues (index 3)
5. Loans (index 4)

Settings accessible via dedicated screen (push route from HomeScreen).

**Navigation pattern**: Simple `MaterialPageRoute` push/pop. No named routes or Navigator 2.0.

**App entry**: SplashScreen → onboarding check → HomeScreen

### Theme System

- **ThemeViewModel**: manages `AppThemeType` + `ThemeMode`
- **AppThemeType** enum: `dynamicColor`, `purple`, `green`, `blue`, `cyan`, `red`, `orange`
  - Each has a `seedColor` and `label`
- **Dynamic Color**: Material You support via `dynamic_color` package, falls back to seed color
- **DynamicColorBuilder**: wraps MaterialApp in main.dart with `Consumer<ThemeViewModel>`
- Persisted via `PreferencesService` (keys: `themeMode`, `themeType`)

### Loan Calculation System

The loan feature has a sophisticated architecture with specialized services:

- **LoanCalculationService** ([lib/core/services/loan_calculation_service.dart](lib/core/services/loan_calculation_service.dart)):
  - Pure functions for financial calculations
  - Handles amortizable and in-fine loan types
  - Calculates monthly payments, remaining capital, interest
  - Supports deferred payment periods (`deferredMonths`: zero payments during deferment)
  - Insurance calculations (fixed, percentage of initial capital, or percentage of remaining capital)

- **LoanPaymentBreakdownService** ([lib/core/services/loan_payment_breakdown_service.dart](lib/core/services/loan_payment_breakdown_service.dart)):
  - Generates detailed payment schedules
  - Breaks down each payment into capital, interest, and insurance

- **Loan** domain entity ([lib/core/domain/loan.dart](lib/core/domain/loan.dart)):
  - Facade over LoanModel + calculation services
  - Exposes computed: `currentMonthlyPayment`, `remainingCapital`, `remainingMonths`, `totalPaidAmount`, `progressPercentage`, `totalCost`, `remainingCost`
  - Status: `isCompleted`, `isPending`, `isActive`, `isInDeferredPeriod`, `getStatus()`

- **Loan Types** ([lib/core/enums/loan_types.dart](lib/core/enums/loan_types.dart)):
  - `LoanRepaymentType.amortizable`: Standard amortization (capital repaid progressively)
  - `LoanRepaymentType.inFine`: Interest-only payments, capital due at end

- **Insurance Modes**:
  - `LoanInsuranceType.none`: No insurance
  - `LoanInsuranceType.fixed`: Fixed monthly amount
  - `LoanInsuranceType.percentage`: Percentage of capital

- **Insurance Calculation Modes**:
  - `InsuranceCalculationMode.initialCapital`: Fixed monthly (% of initial capital)
  - `InsuranceCalculationMode.remainingCapital`: Decreasing monthly (% of remaining capital)

- **LoanStatus** (in LoanModel):
  - `pending` (À commencer), `partiallyPaid` (En cours), `completed` (Remboursé)
  - Has `getColor(context)` and `icon` for UI

### Form Validation

Models have built-in validators called in ViewModel add/update methods:
- **ExpenseModel**: validates name, amount, categoryId
- **RevenueModel**: validates name, amount, accountId, date
- Validators throw exceptions that propagate to UI for display

### Data Import/Export

- **DataViewModel** ([lib/ui/settings/data_viewmodel.dart](lib/ui/settings/data_viewmodel.dart)):
  - Exports all data (accounts, expenses, revenues, loans, categories) to JSON
  - Imports data from JSON backup files with ID remapping for orphaned records
  - Uses `share_plus` for sharing backup files
  - Uses `file_picker` for selecting import files
  - State: `_isExporting`, `_isImporting`, `_isDeleting`, `_importProgress`, `_importStatus`

### Auto-Update System

- **UpdateViewModel** ([lib/ui/settings/update_viewmodel.dart](lib/ui/settings/update_viewmodel.dart)):
  - Checks for new versions via GitHub releases API
  - Filters releases by app type (beta vs production)
  - **GithubService**: fetches and parses latest release info
  - **DownloadService**: downloads APK with progress callback
  - **InstallService**: triggers APK installation via `app_installer`
  - Version comparison uses `version` package

### Preferences System

**PreferencesService** wraps SharedPreferences with typed getters/setters:
- `isFirstLaunch`, `isCategoriesCreated`: onboarding flags
- `themeMode`, `themeType`: theme persistence
- `annualExpenseCalculationMode`: expense display mode
- `skipAuth`, `notifications`, `exportFrequency`: other settings

### App Restart

Uses `restart_app` package via `RestartWidget` wrapper in main.dart. Called after data reset to cleanly re-initialize ObjectBox.

### Testing

- Tests located in `test/unit/` (viewmodels, models, services, utils)
- Uses `mocktail` for mocking repositories and services
- Widget tests in `test/widget/`
- CI runs tests on PRs via GitHub Actions

**Test coverage:**
- ViewModels: expense, account, loan, category, revenues, settings, data, update, dashboard, loan_creation, loan_edit, theme
- Models: account, expense, revenue, category
- Services: loan_calculation, loan_payment_breakdown, github
- Utils: extensions (DateExtension)
- Widgets: loan_summary_card, appearance_section, category_summary_card

## Important Patterns

### Adding a New Feature with ObjectBox

1. Create model in `lib/models/` with `@Entity()` annotation + `toJson()`/`fromJson()`
2. Run `flutter pub run build_runner build` to generate ObjectBox code
3. Add box to `ObjectBoxService` (in `_init()` method)
4. Create repository in `lib/core/repositories/`
5. Create ViewModel extending `ChangeNotifier`
6. Register repository and ViewModel in `main.dart` providers
7. Create UI in `lib/ui/`

### ViewModel Pattern

ViewModels should:
- Accept repositories via constructor
- Initialize data in constructor or `loadData()` method
- Expose state as getters (`expenses`, `isLoading`, `error`)
- Use `try-catch-finally` with `notifyListeners()`
- Call `notifyListeners()` after state changes
- Handle error as `String? _error` set in catch, cleared before operations

### Listener Cleanup Pattern

When a ViewModel listens to another ViewModel:
```dart
_otherViewModel.addListener(_notifyListeners);

@override
void dispose() {
  _otherViewModel.removeListener(_notifyListeners);
  super.dispose();
}
```
Used in: AccountViewModel, DashboardViewModel.

### Working with Provider

- Use `context.read<T>()` for one-time reads (e.g., calling methods)
- Use `context.watch<T>()` or `Consumer<T>` to rebuild on changes
- Avoid calling `notifyListeners()` inside build methods

### Handling Complex Dependencies

When a ViewModel depends on other ViewModels (not just repositories):
- Use `ChangeNotifierProxyProvider` or `ChangeNotifierProxyProvider4`
- Example: AccountViewModel depends on ExpenseViewModel, RevenueViewModel, LoanViewModel
- See [lib/main.dart](lib/main.dart) for the pattern

### JSON Serialization

All ObjectBox models implement:
- `toJson()`: Converts model to `Map<String, dynamic>`
- `fromJson()`: Factory constructor to create model from JSON
- IDs stored as strings in JSON
- Used for data export/import in DataViewModel

### Category Icon Resolution

`CategoryModel.getIconData()` maps icon name strings to `IconData`. Always use this method when displaying category icons in the UI.

## Build Flavors

The app uses Flutter flavors for different environments:
- **Production** (`prod`): Default flavor for release builds — `flutter build apk --flavor prod --release`
- **Beta** (`beta`): Testing flavor — `flutter build apk --flavor beta --release`
  - Used in CI/CD for beta releases on GitHub (tagged with `-beta` suffix, marked as prerelease)

## Branch Strategy

- Main branch: `main`
- Active development branch: `beta`
- Create PRs to `main`

## CI/CD Workflows (.github/workflows/)

- **test.yml**: Runs `flutter test` on every PR
- **lint.yml**: Runs `flutter analyze` on every PR
- **release.yml**: On push to `main` — builds prod APK, creates GitHub release with tag
- **beta-release.yml**: On push to `beta` — builds beta APK, creates prerelease with `-beta` tag
