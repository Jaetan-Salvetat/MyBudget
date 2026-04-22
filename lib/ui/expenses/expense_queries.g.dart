// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeExpenses)
final activeExpensesProvider = ActiveExpensesProvider._();

final class ActiveExpensesProvider
    extends
        $FunctionalProvider<
          List<ExpenseModel>,
          List<ExpenseModel>,
          List<ExpenseModel>
        >
    with $Provider<List<ExpenseModel>> {
  ActiveExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeExpensesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeExpensesHash();

  @$internal
  @override
  $ProviderElement<List<ExpenseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ExpenseModel> create(Ref ref) {
    return activeExpenses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ExpenseModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ExpenseModel>>(value),
    );
  }
}

String _$activeExpensesHash() => r'f0feff22243757a89e914340cfb66401023e9086';

@ProviderFor(monthlyExpenses)
final monthlyExpensesProvider = MonthlyExpensesProvider._();

final class MonthlyExpensesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  MonthlyExpensesProvider._()
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

String _$monthlyExpensesHash() => r'bb853c5ff4061944bab9a0ecab331425ba5a6e1a';

@ProviderFor(currentMonthExpenses)
final currentMonthExpensesProvider = CurrentMonthExpensesProvider._();

final class CurrentMonthExpensesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  CurrentMonthExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthExpensesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthExpensesHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return currentMonthExpenses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$currentMonthExpensesHash() =>
    r'ec4fef5f1b1ed1032f55b92d2938eb61d90f5d44';

@ProviderFor(annualExpenses)
final annualExpensesProvider = AnnualExpensesProvider._();

final class AnnualExpensesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  AnnualExpensesProvider._()
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

String _$annualExpensesHash() => r'f5e7daf4d2018b6d156744687353fb1abc9a9643';

@ProviderFor(upcomingExpenses)
final upcomingExpensesProvider = UpcomingExpensesProvider._();

final class UpcomingExpensesProvider
    extends
        $FunctionalProvider<
          List<ExpenseModel>,
          List<ExpenseModel>,
          List<ExpenseModel>
        >
    with $Provider<List<ExpenseModel>> {
  UpcomingExpensesProvider._()
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

String _$upcomingExpensesHash() => r'8908328bd73786860ade4a4427ef726b3d45604b';

@ProviderFor(expensesByCategory)
final expensesByCategoryProvider = ExpensesByCategoryProvider._();

final class ExpensesByCategoryProvider
    extends
        $FunctionalProvider<
          Map<CategoryModel, double>,
          Map<CategoryModel, double>,
          Map<CategoryModel, double>
        >
    with $Provider<Map<CategoryModel, double>> {
  ExpensesByCategoryProvider._()
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
    r'2e7cd2ea7e75fbd950db929edc57de78513dd1be';
