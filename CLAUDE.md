# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyBudget is a local-first personal finance management Flutter application. It uses ObjectBox for local data storage and follows an MVVM architecture with the Provider pattern for state management. The app features a "Glassmorphism" (Frosted UI) design system.

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
flutter build apk

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
   - Each model has a `copyWith()` method for immutability

2. **Repositories** (`lib/core/repositories/`): Thin wrappers around ObjectBox `Box<T>`
   - Provide CRUD operations (getAll, add, update, delete)
   - Example: `ExpenseRepository`, `AccountRepository`

3. **ViewModels** (`lib/ui/*/`): Extend `ChangeNotifier`
   - Consume repositories via dependency injection
   - Expose data and state to UI
   - Call `notifyListeners()` to trigger UI updates
   - Located alongside their respective screens

4. **UI** (`lib/ui/`): Organized by feature (dashboard, accounts, expenses, revenues, loans, settings)
   - Each feature has screens, ViewModels, and widgets
   - Uses `Consumer` or `context.watch/read` to access ViewModels

### Dependency Injection

All dependencies are wired in [lib/main.dart](lib/main.dart) using `MultiProvider`:
- Services (ObjectBoxService, PreferencesService) are initialized first
- Repositories are created from ObjectBox boxes
- ViewModels are provided as `ChangeNotifierProvider` or `ChangeNotifierProxyProvider`
- Complex dependencies use `ChangeNotifierProxyProvider4` (e.g., AccountViewModel depends on 4 other ViewModels)

### Data Flow

```
ObjectBoxService (initializes Store)
  → Repositories (wrap Box<T>)
  → ViewModels (business logic + state)
  → UI (renders data)
```

## Key Technical Details

### ObjectBox Setup

- **Service**: [lib/core/services/objectbox_service.dart](lib/core/services/objectbox_service.dart)
- Singleton pattern with `getInstance()`
- Generated code in [lib/objectbox.g.dart](lib/objectbox.g.dart)
- Schema in [lib/objectbox-model.json](lib/objectbox-model.json)
- After modifying `@Entity` models, regenerate with: `flutter pub run build_runner build`

### Date Handling

- **Locale**: 'fr_FR' (initialized in main.dart)
- **Storage**: `DateTime` stored as ObjectBox `@Property()`
- **Formatting**: Custom `DateExtension` in [lib/utils/extensions.dart](lib/utils/extensions.dart)
- **Important Rule**: Year is ignored for recurring expenses
  - Monthly: Only day matters (e.g., every 15th)
  - Annual: Day + month matter (e.g., every Jan 15)

### Frequency System

See [lib/core/enums/frequency.dart](lib/core/enums/frequency.dart):
- `Frequency.monthly`: Recurring every month
- `Frequency.annual`: Recurring every year

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

The package is imported from GitHub:
```dart
import 'package:frosted_ui/frosted_ui.dart';
```

Available components:
- `FrostedScaffold`, `FrostedAppBar`, `FrostedGlassContainer`
- `FrostedTextField`, `FrostedButton`, `FrostedTextButton`, `FrostedIconButton`
- `FrostedCard`, `FrostedBottomSheet`, `FrostedDialog`
- `FrostedBottomNavigationBar` for main navigation
- `FrostedDivider`
- Inline validation with contextual error messages

### Navigation Structure

Main screen is [lib/ui/home/home_screen.dart](lib/ui/home/home_screen.dart) with bottom navigation:
1. Dashboard (index 0)
2. Accounts (index 1)
3. Expenses (index 2)
4. Revenues (index 3)
5. Loans (index 4)

Settings accessible via dedicated screen.

### Loan Calculation System

The loan feature has a sophisticated architecture with specialized services:

- **LoanCalculationService** ([lib/core/services/loan_calculation_service.dart](lib/core/services/loan_calculation_service.dart)):
  - Pure functions for financial calculations
  - Handles amortizable and in-fine loan types
  - Calculates monthly payments, remaining capital, interest
  - Supports deferred payment periods
  - Insurance calculations (fixed, percentage, or based on remaining capital)

- **LoanPaymentBreakdownService** ([lib/core/services/loan_payment_breakdown_service.dart](lib/core/services/loan_payment_breakdown_service.dart)):
  - Generates detailed payment schedules
  - Breaks down each payment into capital, interest, and insurance

- **Loan Types** ([lib/core/enums/loan_types.dart](lib/core/enums/loan_types.dart)):
  - `LoanRepaymentType.amortizable`: Standard amortization schedule
  - `LoanRepaymentType.inFine`: Interest-only payments, capital due at end

- **Insurance Modes**:
  - `LoanInsuranceType.none`: No insurance
  - `LoanInsuranceType.fixed`: Fixed monthly amount
  - `LoanInsuranceType.percentage`: Percentage of initial or remaining capital

### Data Import/Export

- **DataViewModel** ([lib/ui/settings/data_viewmodel.dart](lib/ui/settings/data_viewmodel.dart)):
  - Exports all data (accounts, expenses, revenues, loans, categories) to JSON
  - Imports data from JSON backup files
  - Uses `share_plus` for sharing backup files
  - Uses `file_picker` for selecting import files

### Auto-Update System

- **UpdateViewModel** ([lib/ui/settings/update_viewmodel.dart](lib/ui/settings/update_viewmodel.dart)):
  - Checks for new versions via GitHub releases
  - **GithubService** fetches latest release info
  - **DownloadService** downloads APK updates
  - **InstallService** triggers installation
  - Version comparison uses `version` package

### Testing

- Tests located in `test/unit/` (viewmodels, models, services)
- Uses `mocktail` for mocking repositories and services
- All ViewModels and critical services have corresponding test files
- Widget tests in `test/widget/`
- CI runs tests on PRs via GitHub Actions (.github/workflows/)

## Important Patterns

### Adding a New Feature with ObjectBox

1. Create model in `lib/models/` with `@Entity()` annotation
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

### Working with Provider

- Use `context.read<T>()` for one-time reads (e.g., calling methods)
- Use `context.watch<T>()` or `Consumer<T>` to rebuild on changes
- Avoid calling `notifyListeners()` inside build methods

### Handling Complex Dependencies

When a ViewModel depends on other ViewModels (not just repositories):
- Use `ChangeNotifierProxyProvider` or `ChangeNotifierProxyProvider4`
- Example: AccountViewModel depends on ExpenseViewModel, RevenueViewModel, LoanViewModel
- See [lib/main.dart](lib/main.dart) lines 126-156 for the pattern

### JSON Serialization

All ObjectBox models should implement:
- `toJson()`: Converts model to Map<String, dynamic>
- `fromJson()`: Factory constructor to create model from JSON
- Used for data export/import functionality
- IDs are stored as strings in JSON

## Build Flavors

The app uses Flutter flavors for different environments:
- **Production**: Default flavor for release builds
- **Beta**: Testing flavor with separate configuration
  - Build: `flutter build apk --flavor beta --release`
  - Used in CI/CD for beta releases on GitHub

## Branch Strategy

- Main branch: `main`
- Current working branch: `beta`
- Create PRs to `main`
