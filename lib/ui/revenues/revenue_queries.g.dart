// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(revenueHistory)
final revenueHistoryProvider = RevenueHistoryProvider._();

final class RevenueHistoryProvider
    extends
        $FunctionalProvider<
          List<RevenueModel>,
          List<RevenueModel>,
          List<RevenueModel>
        >
    with $Provider<List<RevenueModel>> {
  RevenueHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revenueHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revenueHistoryHash();

  @$internal
  @override
  $ProviderElement<List<RevenueModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<RevenueModel> create(Ref ref) {
    return revenueHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RevenueModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RevenueModel>>(value),
    );
  }
}

String _$revenueHistoryHash() => r'601d44e7096774c31d47c263b075d69dee99776e';

@ProviderFor(monthRevenues)
final monthRevenuesProvider = MonthRevenuesProvider._();

final class MonthRevenuesProvider
    extends
        $FunctionalProvider<
          List<RevenueModel>,
          List<RevenueModel>,
          List<RevenueModel>
        >
    with $Provider<List<RevenueModel>> {
  MonthRevenuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthRevenuesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthRevenuesHash();

  @$internal
  @override
  $ProviderElement<List<RevenueModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<RevenueModel> create(Ref ref) {
    return monthRevenues(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RevenueModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RevenueModel>>(value),
    );
  }
}

String _$monthRevenuesHash() => r'bbe604c1085ddf6b0eaeb1b329ad436dabcd4344';

@ProviderFor(activeRevenues)
final activeRevenuesProvider = ActiveRevenuesProvider._();

final class ActiveRevenuesProvider
    extends
        $FunctionalProvider<
          List<RevenueModel>,
          List<RevenueModel>,
          List<RevenueModel>
        >
    with $Provider<List<RevenueModel>> {
  ActiveRevenuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRevenuesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRevenuesHash();

  @$internal
  @override
  $ProviderElement<List<RevenueModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<RevenueModel> create(Ref ref) {
    return activeRevenues(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RevenueModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RevenueModel>>(value),
    );
  }
}

String _$activeRevenuesHash() => r'5360dd45f9e7cef6c89b9da0a1e4f4966d5cad3b';

@ProviderFor(monthlyRevenues)
final monthlyRevenuesProvider = MonthlyRevenuesProvider._();

final class MonthlyRevenuesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  MonthlyRevenuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyRevenuesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyRevenuesHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return monthlyRevenues(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$monthlyRevenuesHash() => r'f87f1a7b5ef64d84f52e4ca7c250e55d789a612c';

@ProviderFor(currentMonthRevenues)
final currentMonthRevenuesProvider = CurrentMonthRevenuesProvider._();

final class CurrentMonthRevenuesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  CurrentMonthRevenuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthRevenuesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthRevenuesHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return currentMonthRevenues(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$currentMonthRevenuesHash() =>
    r'1488b8d5ed6f4b6f9dcfb5c49f086dc5cd7bde21';

@ProviderFor(upcomingRevenues)
final upcomingRevenuesProvider = UpcomingRevenuesProvider._();

final class UpcomingRevenuesProvider
    extends
        $FunctionalProvider<
          List<RevenueModel>,
          List<RevenueModel>,
          List<RevenueModel>
        >
    with $Provider<List<RevenueModel>> {
  UpcomingRevenuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingRevenuesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingRevenuesHash();

  @$internal
  @override
  $ProviderElement<List<RevenueModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<RevenueModel> create(Ref ref) {
    return upcomingRevenues(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RevenueModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RevenueModel>>(value),
    );
  }
}

String _$upcomingRevenuesHash() => r'c3677c5e943e6b1d04781a051646d84d8b995a06';

@ProviderFor(revenueEvents)
final revenueEventsProvider = RevenueEventsFamily._();

final class RevenueEventsProvider
    extends
        $FunctionalProvider<
          List<TransactionEventModel>,
          List<TransactionEventModel>,
          List<TransactionEventModel>
        >
    with $Provider<List<TransactionEventModel>> {
  RevenueEventsProvider._({
    required RevenueEventsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'revenueEventsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$revenueEventsHash();

  @override
  String toString() {
    return r'revenueEventsProvider'
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
    return revenueEvents(ref, argument);
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
    return other is RevenueEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$revenueEventsHash() => r'77f9e1ccfc86e24f601bb921a773a14354a7cf7f';

final class RevenueEventsFamily extends $Family
    with $FunctionalFamilyOverride<List<TransactionEventModel>, int> {
  RevenueEventsFamily._()
    : super(
        retry: null,
        name: r'revenueEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  RevenueEventsProvider call(int rootId) =>
      RevenueEventsProvider._(argument: rootId, from: this);

  @override
  String toString() => r'revenueEventsProvider';
}
