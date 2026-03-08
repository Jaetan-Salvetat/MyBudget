# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyBudget is a local-first personal finance management Flutter application. It uses ObjectBox for local data storage and follows an MVVM architecture with the Provider pattern for state management. The app features a "Glassmorphism" (Frosted UI) design system.

**Important concept**: MyBudget is a **static budget** app. It only tracks fixed, predictable income and expenses (rent, subscriptions, salary, loans, etc.). Variable/punctual spending (groceries, restaurants, impulse purchases) is intentionally out of scope. The goal is to give a clear picture of recurring financial commitments, not to track every transaction.

**Language**: French (fr_FR locale)
**Flutter SDK**: ^3.7.2
**Current version**: 0.3.2+19

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
   - AccountModel, ExpenseModel, RevenueModel, LoanModel, CategoryModel, BeneficiaryModel
   - Each model has a `copyWith()`, `toJson()`, `fromJson()` method
   - Non-ObjectBox utility models: PrivacySettingsModel, ReleaseInfoModel, ExpenseFilterData, CategoryDetailModel

2. **Repositories** (`lib/core/repositories/`): Thin wrappers around ObjectBox `Box<T>`
   - Provide CRUD operations: `getAll()`, `get(id)`, `add()`, `update()`, `delete()`, `deleteAll()`
   - 6 repositories: `AccountRepository`, `ExpenseRepository`, `RevenueRepository`, `LoanRepository`, `CategoryRepository`, `BeneficiaryRepository`

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
- Complex dependencies use `ChangeNotifierProxyProvider4` (e.g., AccountViewModel depends on multiple other ViewModels)

**Provider order in main.dart:**
1. ObjectBoxService (value)
2. Repositories (6 repos: Account, Expense, Revenue, Loan, Category, Beneficiary)
3. Simple ViewModels: SettingsViewModel, UpdateViewModel, ThemeViewModel, CategoryViewModel, BeneficiaryViewModel, ExpenseViewModel, RevenueViewModel, LoanViewModel
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
- Boxes: categoryBox, expenseBox, revenueBox, accountBox, loanBox, beneficiaryBox
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

### Annual Expense Calculation

Annual expenses are always amortized: `amount / 12` spread across all months.
There is no configuration mode for this — it is fixed behavior in `ExpenseViewModel.getTotalExpenses()`.

### Beneficiary System

Expenses and revenues can be linked to a **beneficiary** (e.g., a person or organization).

- **BeneficiaryModel** (`lib/models/beneficiary_model.dart`): ObjectBox entity with `id`, `name`
- **BeneficiaryRepository** (`lib/core/repositories/beneficiary_repository.dart`): standard CRUD
- **BeneficiaryViewModel** (`lib/ui/...`): manages list of beneficiaries
- **BeneficiarySelector** (`lib/ui/common/widgets/beneficiary_selector.dart`):
  - Uses `Consumer<BeneficiaryViewModel>` internally — **do NOT pass a static list as parameter**
  - Creates beneficiaries inline without closing the bottom sheet
  - Props: `initialBeneficiaryId`, `onChanged`

### Revenue Types

`RevenueModel` has an `isRegular` boolean field:
- `isRegular = true`: fixed, recurring salary/income — shown in dashboard totals
- `isRegular = false`: occasional/one-time income — separated in the UI list

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

The package is imported from GitHub (public repo):
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
  - Exports all data (accounts, expenses, revenues, loans, categories, beneficiaries) to JSON
  - Imports data from JSON backup files with ID remapping for orphaned records
  - Uses `share_plus` for sharing backup files
  - Uses `file_picker` for selecting import files
  - State: `_isExporting`, `_isImporting`, `_isDeleting`, `_importProgress`, `_importStatus`

### Auto-Update System

- **UpdateViewModel** ([lib/ui/settings/update_viewmodel.dart](lib/ui/settings/update_viewmodel.dart)):
  - Checks for new versions via GitHub releases API
  - Filters releases by app type: beta (`isBeta = packageName.endsWith('.beta')`) vs production
  - Version comparison: strips `-beta` suffix before `Version.parse()` on both current and remote versions
  - **GithubService**: fetches releases, injects `GITHUB_TOKEN` from `.env` via `flutter_dotenv` for private repo access
  - **DownloadService**: downloads APK with progress callback
  - **InstallService**: triggers APK installation via `app_installer`
  - Version comparison uses `version` package

### Environment Variables (.env)

The app uses `flutter_dotenv` to load a `.env` file at startup (in `main.dart`):
```
GITHUB_TOKEN=your_pat_token_here
```
- The `.env` file is **gitignored** and must be created manually locally
- In CI/CD, the `.env` is created from the `GITHUB_TOKEN_READONLY` GitHub secret (not `GITHUB_TOKEN` which is reserved)
- The token requires **Contents: Read-only** access on the GitHub repo
- Used by `GithubService` to authenticate API requests (supports private repos)

### Preferences System

**PreferencesService** wraps SharedPreferences with typed getters/setters:
- `isFirstLaunch`, `isCategoriesCreated`: onboarding flags
- `themeMode`, `themeType`: theme persistence
- `skipAuth`, `notifications`, `exportFrequency`: other settings

### App Restart

Uses `restart_app` package via `RestartWidget` wrapper in main.dart. Called after data reset to cleanly re-initialize ObjectBox.

### Testing

- Tests located in `test/unit/` (viewmodels, models, services, utils)
- Uses `mocktail` for mocking repositories and services
- Widget tests in `test/widget/`
- CI runs tests on PRs via GitHub Actions

**Test coverage:**
- ViewModels: expense, account, loan, category, revenues, settings, data, update, dashboard, loan_creation, loan_edit, theme, beneficiary
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
  - `applicationId`: `fr.jaetan.mybudget`
- **Beta** (`beta`): Testing flavor — `flutter build apk --flavor beta --release`
  - `applicationId`: `fr.jaetan.mybudget.beta` (`.beta` suffix used by UpdateViewModel to detect beta builds)
  - `versionNameSuffix`: `-beta` (stripped before version comparison in UpdateViewModel)
  - Marked as prerelease on GitHub

## Android Build Configuration

- **Kotlin Gradle Plugin**: `2.1.0` (in `android/settings.gradle.kts`)
- **AGP**: `8.7.0`
- **Java**: `VERSION_17` (source + target, in `android/app/build.gradle.kts`)
- **NDK**: `27.0.12077973`
- `-Xlint:-options` applied globally in `android/build.gradle.kts` to suppress Java 8 obsolete warnings from third-party plugin sub-projects

## Branch Strategy

- Main branch: `main`
- Active development branch: `beta`
- Create PRs to `main`

## CI/CD Workflows (.github/workflows/)

- **test.yml**: Runs `flutter test` on every PR
- **lint.yml**: Runs `flutter analyze` on every PR
- **release.yml**: On push to `main` — builds prod APK (`--flavor prod`), creates GitHub release with version tag, creates `.env` from `GITHUB_TOKEN_READONLY` secret
- **beta-release.yml**: On push to `beta` — builds beta APK (`--flavor beta`), creates prerelease with `-beta` tag, creates `.env` from `GITHUB_TOKEN_READONLY` secret

> **Note**: Use `GITHUB_TOKEN_READONLY` as the secret name in GitHub repo settings — `GITHUB_TOKEN` is a reserved name in GitHub Actions and would be overwritten.
