// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Total mensuel des dépenses (annuelles ramenées sur 12 mois).

@ProviderFor(monthlyExpenses)
const monthlyExpensesProvider = MonthlyExpensesProvider._();

/// Total mensuel des dépenses (annuelles ramenées sur 12 mois).

final class MonthlyExpensesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Total mensuel des dépenses (annuelles ramenées sur 12 mois).
  const MonthlyExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyExpensesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyExpensesHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return monthlyExpenses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$monthlyExpensesHash() => r'11cf1f52b76287cb591f7c0ef2c8c6706d8d9076';

/// Total annuel des dépenses (mensuelles × 12 + annuelles).

@ProviderFor(annualExpenses)
const annualExpensesProvider = AnnualExpensesProvider._();

/// Total annuel des dépenses (mensuelles × 12 + annuelles).

final class AnnualExpensesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Total annuel des dépenses (mensuelles × 12 + annuelles).
  const AnnualExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'annualExpensesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$annualExpensesHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return annualExpenses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$annualExpensesHash() => r'8f755460f386349785c5806946527aa7fa5a1839';

/// Dépenses dont l'échéance tombe à partir d'aujourd'hui dans le mois courant.

@ProviderFor(upcomingExpenses)
const upcomingExpensesProvider = UpcomingExpensesProvider._();

/// Dépenses dont l'échéance tombe à partir d'aujourd'hui dans le mois courant.

final class UpcomingExpensesProvider
    extends
        $FunctionalProvider<
          List<ExpenseModel>,
          List<ExpenseModel>,
          List<ExpenseModel>
        >
    with $Provider<List<ExpenseModel>> {
  /// Dépenses dont l'échéance tombe à partir d'aujourd'hui dans le mois courant.
  const UpcomingExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingExpensesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingExpensesHash();

  @$internal
  @override
  $ProviderElement<List<ExpenseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ExpenseModel> create(Ref ref) {
    return upcomingExpenses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ExpenseModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ExpenseModel>>(value),
    );
  }
}

String _$upcomingExpensesHash() => r'160b947f4d25885fe9e01fa681e26f3e4cf968c2';

/// Dépenses agrégées par catégorie (Map<CategoryModel, montant>).

@ProviderFor(expensesByCategory)
const expensesByCategoryProvider = ExpensesByCategoryProvider._();

/// Dépenses agrégées par catégorie (Map<CategoryModel, montant>).

final class ExpensesByCategoryProvider
    extends
        $FunctionalProvider<
          Map<CategoryModel, double>,
          Map<CategoryModel, double>,
          Map<CategoryModel, double>
        >
    with $Provider<Map<CategoryModel, double>> {
  /// Dépenses agrégées par catégorie (Map<CategoryModel, montant>).
  const ExpensesByCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesByCategoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesByCategoryHash();

  @$internal
  @override
  $ProviderElement<Map<CategoryModel, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<CategoryModel, double> create(Ref ref) {
    return expensesByCategory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<CategoryModel, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<CategoryModel, double>>(value),
    );
  }
}

String _$expensesByCategoryHash() =>
    r'6ed0ec7a6cee69a900861f5d7247c44ffc5f0fb3';
