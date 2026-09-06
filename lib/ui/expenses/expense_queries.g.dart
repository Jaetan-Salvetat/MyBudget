// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(expenseHistory)
final expenseHistoryProvider = ExpenseHistoryProvider._();

final class ExpenseHistoryProvider
    extends
        $FunctionalProvider<
          List<ExpenseModel>,
          List<ExpenseModel>,
          List<ExpenseModel>
        >
    with $Provider<List<ExpenseModel>> {
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

@ProviderFor(monthExpenses)
final monthExpensesProvider = MonthExpensesProvider._();

final class MonthExpensesProvider
    extends
        $FunctionalProvider<
          List<ExpenseModel>,
          List<ExpenseModel>,
          List<ExpenseModel>
        >
    with $Provider<List<ExpenseModel>> {
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

String _$monthExpensesHash() => r'7847b07fc2db97b95a831a44388d42e8af59ce99';

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

String _$monthlyExpensesHash() => r'00adf41dceb29a992ac66b45e571ee3e82131948';

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
    r'3a2a09b1e90ec8a545c75b00f6a3d5ed6b65fd66';

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

String _$upcomingExpensesHash() => r'c08dd13165d01faf4773d067c93624f63f67e684';

@ProviderFor(expensesByGroup)
final expensesByGroupProvider = ExpensesByGroupProvider._();

final class ExpensesByGroupProvider
    extends
        $FunctionalProvider<
          Map<String, double>,
          Map<String, double>,
          Map<String, double>
        >
    with $Provider<Map<String, double>> {
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

String _$expensesByGroupHash() => r'4d8caf00934a2f20cd00a167783c39ddb6275982';

@ProviderFor(expenseEvents)
final expenseEventsProvider = ExpenseEventsFamily._();

final class ExpenseEventsProvider
    extends
        $FunctionalProvider<
          List<TransactionEventModel>,
          List<TransactionEventModel>,
          List<TransactionEventModel>
        >
    with $Provider<List<TransactionEventModel>> {
  ExpenseEventsProvider._({
    required ExpenseEventsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'expenseEventsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expenseEventsHash();

  @override
  String toString() {
    return r'expenseEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<TransactionEventModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TransactionEventModel> create(Ref ref) {
    final argument = this.argument as int;
    return expenseEvents(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransactionEventModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransactionEventModel>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseEventsHash() => r'c5380a51d18b842b0a327589b38d6c56ab082023';

final class ExpenseEventsFamily extends $Family
    with $FunctionalFamilyOverride<List<TransactionEventModel>, int> {
  ExpenseEventsFamily._()
    : super(
        retry: null,
        name: r'expenseEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ExpenseEventsProvider call(int rootId) =>
      ExpenseEventsProvider._(argument: rootId, from: this);

  @override
  String toString() => r'expenseEventsProvider';
}
