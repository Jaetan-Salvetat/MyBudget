// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every rule ever recorded, the closed ones included. Editing or deleting a
/// recurring expense closes its row and opens another : reading only the open
/// ones would erase the months the closed one was actually paid in.

@ProviderFor(expenseHistory)
final expenseHistoryProvider = ExpenseHistoryProvider._();

/// Every rule ever recorded, the closed ones included. Editing or deleting a
/// recurring expense closes its row and opens another : reading only the open
/// ones would erase the months the closed one was actually paid in.

final class ExpenseHistoryProvider
    extends
        $FunctionalProvider<
          List<ExpenseModel>,
          List<ExpenseModel>,
          List<ExpenseModel>
        >
    with $Provider<List<ExpenseModel>> {
  /// Every rule ever recorded, the closed ones included. Editing or deleting a
  /// recurring expense closes its row and opens another : reading only the open
  /// ones would erase the months the closed one was actually paid in.
  ExpenseHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseHistoryHash();

  @$internal
  @override
  $ProviderElement<List<ExpenseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ExpenseModel> create(Ref ref) {
    return expenseHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ExpenseModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ExpenseModel>>(value),
    );
  }
}

String _$expenseHistoryHash() => r'c36546d58f1ea40b3639382cb783115638e5722f';

/// The rules that fall on the selected month, each dated on the day it lands
/// there. The list drawn on screen and the total announced above it read the
/// same rule, so one can never say something the other denies.

@ProviderFor(monthExpenses)
final monthExpensesProvider = MonthExpensesProvider._();

/// The rules that fall on the selected month, each dated on the day it lands
/// there. The list drawn on screen and the total announced above it read the
/// same rule, so one can never say something the other denies.

final class MonthExpensesProvider
    extends
        $FunctionalProvider<
          List<ExpenseModel>,
          List<ExpenseModel>,
          List<ExpenseModel>
        >
    with $Provider<List<ExpenseModel>> {
  /// The rules that fall on the selected month, each dated on the day it lands
  /// there. The list drawn on screen and the total announced above it read the
  /// same rule, so one can never say something the other denies.
  MonthExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthExpensesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthExpensesHash();

  @$internal
  @override
  $ProviderElement<List<ExpenseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ExpenseModel> create(Ref ref) {
    return monthExpenses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ExpenseModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ExpenseModel>>(value),
    );
  }
}

String _$monthExpensesHash() => r'502bf6d40ca17db1e55ff9be7449740eccc432e5';

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

String _$monthlyExpensesHash() => r'f48ad2e46d97b20f0e25f54787448eef7b09a26a';

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
    r'c9814aedd64dcc3d9b282d85dcd67788e344e552';

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

/// Monthly totals per taxonomy group key, for the dashboard breakdown.
///
/// Aggregation happens at group level: 11 expense groups stay readable where 59
/// leaves would not.

@ProviderFor(expensesByGroup)
final expensesByGroupProvider = ExpensesByGroupProvider._();

/// Monthly totals per taxonomy group key, for the dashboard breakdown.
///
/// Aggregation happens at group level: 11 expense groups stay readable where 59
/// leaves would not.

final class ExpensesByGroupProvider
    extends
        $FunctionalProvider<
          Map<String, double>,
          Map<String, double>,
          Map<String, double>
        >
    with $Provider<Map<String, double>> {
  /// Monthly totals per taxonomy group key, for the dashboard breakdown.
  ///
  /// Aggregation happens at group level: 11 expense groups stay readable where 59
  /// leaves would not.
  ExpensesByGroupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesByGroupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesByGroupHash();

  @$internal
  @override
  $ProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, double> create(Ref ref) {
    return expensesByGroup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$expensesByGroupHash() => r'bd2cba0277c57c6528d82372ce24d9af1a8aef23';
