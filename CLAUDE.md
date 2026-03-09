# CLAUDE.md

## Coding Rules

- **NEVER** use `--delete-conflicting-outputs` with `flutter pub run build_runner build`
- **NEVER** add comments to code (no `//`, no `///`, no `/* */`)
- **Keep CLAUDE.md as concise as possible** — no verbose explanations, only essential information
- **Error handling** — always apply these 3 rules:
  - Notifier mutations (`add`, `update`, `delete`): wrap in `try`/`catch` + `rethrow`
  - UI call sites: wrap notifier calls in `try`/`catch` + `FrostedSnackbar.show(context, message: 'Erreur lors de <op>: $e')`
  - Screens watching async providers: use `AsyncValue.when(data:, loading:, error:)` instead of `.value ?? []`

## Project Overview

MyBudget is a local-first personal finance management Flutter application. It uses ObjectBox for local data storage and follows an MVVM architecture with **Riverpod 3** for state management. The app features a "Glassmorphism" (Frosted UI) design system.

**Static budget app**: only tracks fixed, predictable income/expenses (rent, subscriptions, salary, loans). Variable spending is out of scope.

**Language**: French (fr_FR locale)
**Flutter SDK**: ^3.7.2
**Current version**: 0.4.0+22

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
flutter test test/unit/providers/expense_provider_test.dart

# Lint/analyze code
flutter analyze

# Generate Riverpod + ObjectBox code (after model or provider changes)
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

### MVVM + Repository + Riverpod

The app follows a clear separation of concerns:

1. **Models** (`lib/models/`): ObjectBox entities annotated with `@Entity`
   - AccountModel, ExpenseModel, RevenueModel, LoanModel, CategoryModel, BeneficiaryModel
   - Each model has a `copyWith()`, `toJson()`, `fromJson()` method
   - Non-ObjectBox utility models: ReleaseInfoModel, ExpenseFilterData, RevenueFilterData, CategoryDetailModel

2. **Repositories** (`lib/core/repositories/`): Thin wrappers around ObjectBox `Box<T>`
   - Provide CRUD operations: `getAll()`, `get(id)`, `add()`, `update()`, `delete()`, `deleteAll()`
   - 6 repositories: `AccountRepository`, `ExpenseRepository`, `RevenueRepository`, `LoanRepository`, `CategoryRepository`, `BeneficiaryRepository`

3. **Entities** (`lib/core/entities/`): Facade pattern over models with computed logic
   - `Loan`: wraps `LoanModel` + calculation services, exposes computed properties
   - `LoanPaymentBreakdown`: immutable value object for payment decomposition

4. **Providers** (`lib/ui/*/`): Riverpod `AsyncNotifier` or `Notifier` classes
   - Named `*Notifier` (e.g. `ExpenseNotifier`, `LoanNotifier`)
   - Files named `*_provider.dart` (e.g. `expenses_provider.dart`)
   - Consume repositories via `ref.watch(repositoryProvider)`
   - Expose CRUD methods + query/aggregation methods
   - Use `ref.invalidateSelf()` + `await future` after mutations
   - All annotated with `@Riverpod(keepAlive: true)` and code-generated

5. **UI** (`lib/ui/`): Organized by feature
   - Each feature folder contains: `*_screen.dart`, `*_provider.dart`, `widgets/`
   - Uses `ref.watch()` for reactive reads, `ref.read()` for one-shot calls

### Dependency Injection

All dependencies are wired via Riverpod providers in `lib/core/providers/providers.dart`:
- `ObjectBoxService` initialized at app startup
- Repository providers created from ObjectBox boxes
- Notifier providers annotated with `@Riverpod(keepAlive: true)`

**Riverpod generation**: After adding/modifying a `@riverpod` annotated class or function, run:
```bash
flutter pub run build_runner build
```

### Data Flow

```
ObjectBoxService (initializes Store)
  → Repositories (wrap Box<T>)
  → Notifiers (business logic + state, via ref.watch)
  → UI (ref.watch / ref.read)

LoanModel (persisted) → LoanService.createLoans() → Loan (entity with computed logic)
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
- **⚠️ Known issue**: `fromString()` compares on the French label string, not on `enum.name`. Do not rename labels without updating stored data.

### Annual Expense Calculation

Annual expenses are always amortized: `amount / 12` spread across all months.
There is no configuration mode for this — it is fixed behavior in `ExpenseNotifier.getTotalExpenses()`.

### Beneficiary System

Expenses and revenues can be linked to a **beneficiary** (e.g., a person or organization).

- **BeneficiaryModel** (`lib/models/beneficiary_model.dart`): ObjectBox entity with `id`, `name`
- **BeneficiaryRepository** (`lib/core/repositories/beneficiary_repository.dart`): standard CRUD
- **BeneficiaryNotifier** (`lib/ui/settings/beneficiary_provider.dart`): manages list of beneficiaries
- **BeneficiarySelector** (`lib/ui/common/widgets/beneficiary_selector.dart`):
  - Uses `ref.watch(beneficiaryProvider)` internally — **do NOT pass a static list as parameter**
  - Creates beneficiaries inline without closing the bottom sheet
  - Props: `initialBeneficiaryId`, `onChanged`

### Revenue Types

`RevenueModel` has an `isRegular` boolean field:
- `isRegular = true`: fixed, recurring salary/income — shown in dashboard totals
- `isRegular = false`: occasional/one-time income — separated in the UI list

### Enum Storage Pattern

Models use a consistent pattern for storing enums in ObjectBox:
- Enums are stored as **string IDs** using `enum.name` (e.g., `repaymentTypeId`, `insuranceTypeId`)
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

The package is a private lib imported from GitHub:
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

- **ThemeNotifier** (`lib/core/theme/theme_provider.dart`): manages `AppThemeType` + `ThemeMode`
- **AppThemeType** enum: `dynamicColor`, `purple`, `green`, `blue`, `cyan`, `red`, `orange`
  - Each has a `seedColor` and `label`
- **Dynamic Color**: Material You support via `dynamic_color` package, falls back to seed color
- **DynamicColorBuilder**: wraps MaterialApp in main.dart
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

- **Loan** entity ([lib/core/entities/loan.dart](lib/core/entities/loan.dart)):
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

Models have built-in validators called in Notifier add/update methods:
- **ExpenseModel**: validates name, amount, categoryId
- **RevenueModel**: validates name, amount, accountId, date
- Validators throw exceptions that propagate to UI for display

### Data Import/Export

Architecture in 3 layers:

- **Pure services** (`lib/core/services/data/`):
  - `DataImportService`: validates JSON (`validate()`) THEN executes import (`execute()`) with ID remapping. Receives 6 repositories via constructor. No Riverpod, no BuildContext.
  - `DataExportService`: builds JSON export map (`buildExportData()`) from all repositories. Uses `toJson()` on all models (including loans in camelCase).
  - `ImportReport` / `ImportEntityReport`: value objects with per-entity counters (total, imported, skipped, errors).
  - `ImportValidationResult`: parsed entities with old IDs preserved for remapping.

- **DataNotifier** ([lib/ui/settings/data_provider.dart](lib/ui/settings/data_provider.dart)):
  - Thin orchestrator: delegates to services, manages state transitions.
  - `exportUserData()` → returns temp file path (no BuildContext).
  - `importUserData(String jsonContent)` → validate-then-execute, sets `importReport` in state.
  - `deleteAllUserData()` → deletes all repos + clears preferences (no BuildContext).
  - State fields: `isExporting`, `isImporting`, `isDeleting`, `importProgress`, `importStatus`, `error`, `importReport`.

- **UI** (`data_section.dart`, `data_management_dialogs.dart`):
  - File I/O (`file_picker`, `share_plus`) handled at UI layer.
  - `showImportReportDialog()` displays per-entity import results with icons and counters.

### Auto-Update System

- **UpdateNotifier** ([lib/ui/settings/update_provider.dart](lib/ui/settings/update_provider.dart)):
  - Checks for new versions via GitHub releases API
  - Filters releases by app type: beta (`isBeta = packageName.endsWith('.beta')`) vs production
  - Version comparison: strips `-beta` suffix before `Version.parse()` on both current and remote versions
  - **GithubService**: fetches releases, injects `GITHUB_TOKEN` from `.env` via `flutter_dotenv`
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
- Used by `GithubService` to authenticate API requests

### Preferences System

**PreferencesService** (`lib/core/services/preferences_service.dart`) wraps SharedPreferences with typed static getters/setters. Must be initialized at startup with `await PreferencesService.init()` before use.

Available keys:
- `isFirstLaunch()`, `setNotFirstLaunch()`: onboarding flag
- `isCategoriesCreated()`, `setCategoriesCreated()`: onboarding flag
- `getThemeMode()`, `setThemeMode()`: ThemeMode persistence
- `getThemeType()`, `setThemeType()`: AppThemeType persistence

### App Restart

Uses `restart_app` package via `RestartWidget` wrapper in main.dart. Called after data reset to cleanly re-initialize ObjectBox.

## Important Patterns

### Adding a New Feature with ObjectBox

1. Create model in `lib/models/` with `@Entity()` annotation + `toJson()`/`fromJson()`
2. Run `flutter pub run build_runner build`
3. Add box to `ObjectBoxService` (in `_init()` method)
4. Create repository in `lib/core/repositories/`
5. Create `*_provider.dart` in `lib/ui/<feature>/` with `@Riverpod(keepAlive: true)` annotation
6. Run build_runner again to generate the `.g.dart` file
7. Register repository provider in `lib/core/providers/providers.dart`
8. Create UI in `lib/ui/<feature>/`

### Notifier Pattern (Riverpod)

Notifiers should:
- Extend `_$NotifierName` (generated)
- Load data in `build()` via `ref.watch(repositoryProvider)`
- Expose CRUD methods that call `ref.invalidateSelf()` + `await future` after mutations
- Expose query/aggregation methods that compute from `state.value ?? []`
- Be annotated with `@Riverpod(keepAlive: true)`

Example:
```dart
@Riverpod(keepAlive: true)
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Future<List<ExpenseModel>> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getAll();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    ref.read(expenseRepositoryProvider).add(expense);
    ref.invalidateSelf();
    await future;
  }

  List<ExpenseModel> get _expenses => state.value ?? [];

  double getMonthlyExpenses() { /* compute from _expenses */ }
}
```

### Derived Providers (for shared computed values)

When a computed value is used by multiple features (e.g., dashboard + account details),
prefer a **derived provider** over a method on the notifier:

```dart
@riverpod
double monthlyExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  return ExpenseQueryService.getMonthlyExpenses(expenses);
}
```

This is the idiomatic Riverpod approach: each computed value is an autonomous, reactive, testable provider.

### Working with Riverpod in UI

- Use `ref.watch(provider)` to rebuild on state changes
- Use `ref.read(provider.notifier).method()` for one-shot calls (e.g., button taps)
- Use `AsyncValue.when(data:, loading:, error:)` to handle async provider states

### JSON Serialization

All ObjectBox models implement:
- `toJson()`: Converts model to `Map<String, dynamic>`
- `fromJson()`: Factory constructor to create model from JSON
- IDs stored as strings in JSON
- Used for data export/import in DataNotifier

### Category Icon Resolution

`CategoryModel.getIconData()` maps icon name strings to `IconData`. Always use this method when displaying category icons in the UI.

## Testing

### Test structure

```
test/
├── unit/
│   ├── providers/
│   ├── models/
│   ├── services/
│   └── utils/
└── widget/
```

### Test conventions

- Uses `mocktail` for mocking repositories
- Provider tests use `ProviderContainer` with `overrides`
- Always `await container.read(xxxProvider.future)` before reading state for AsyncNotifiers
- `SharedPreferences.setMockInitialValues({})` + `await PreferencesService.init()` in `setUp` when testing providers that depend on preferences
- Use `addTearDown(container.dispose)` to clean up containers

**Test coverage (189 tests passing):**
- Providers: expense, account, loan, loan_creation, loan_edit, category, revenues, data, update, dashboard, theme, beneficiary
- Models: account, expense, revenue, category, loan
- Services: loan_calculation, loan_payment_breakdown, github, preferences, data_import, data_export
- Utils: extensions (DateExtension)
- Widgets: loan_summary_card, appearance_section, category_summary_card

## Architecture Backlog

Known issues and planned refactors (do not implement without explicit instruction):

| Priority | Item | Description |
|---|---|---|
| Low | UI data layer | Create display data classes (`ExpenseDisplayData`, etc.) to decouple UI from ObjectBox models |
| Low | Error handling | Add `try-catch` + error state in all Notifiers, display errors in UI |

## Versioning

- **pubspec.yaml**: `x.y.z+BUILD` — no beta suffix (e.g. `0.4.0+22`)
- **`+BUILD`** = Android versionCode, incrémenté manuellement dans pubspec
- **Beta CI**: auto-computes `x.y.z-beta.N` via git tags (`git tag -l "vX.Y.Z-beta.*"`), injects via `--build-name`
- **Prod CI**: uses version as-is from pubspec
- **Version stripping** (UpdateNotifier + GitHubService): `RegExp(r'-beta(\.\d+)?')` handles both `-beta` and `-beta.N`

## Build Flavors

The app uses Flutter flavors for different environments:
- **Production** (`prod`): Default flavor for release builds — `flutter build apk --flavor prod --release`
  - `applicationId`: `fr.jaetan.mybudget`
- **Beta** (`beta`): Testing flavor — `flutter build apk --flavor beta --release`
  - `applicationId`: `fr.jaetan.mybudget.beta` (`.beta` suffix used by UpdateNotifier to detect beta builds)
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
- **beta-release.yml**: Manual trigger (`workflow_dispatch`) — builds beta APK (`--flavor beta`), auto-increments `x.y.z-beta.N` via git tags, creates prerelease

> **Note**: Use `GITHUB_TOKEN_READONLY` as the secret name in GitHub repo settings — `GITHUB_TOKEN` is a reserved name in GitHub Actions and would be overwritten.
