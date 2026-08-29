// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every rule ever recorded, the closed ones included : reading only the open
/// ones would erase the months a since-closed revenue was actually received.

@ProviderFor(revenueHistory)
final revenueHistoryProvider = RevenueHistoryProvider._();

/// Every rule ever recorded, the closed ones included : reading only the open
/// ones would erase the months a since-closed revenue was actually received.

final class RevenueHistoryProvider
    extends
        $FunctionalProvider<
          List<RevenueModel>,
          List<RevenueModel>,
          List<RevenueModel>
        >
    with $Provider<List<RevenueModel>> {
  /// Every rule ever recorded, the closed ones included : reading only the open
  /// ones would erase the months a since-closed revenue was actually received.
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

/// The rules that fall on the selected month, each dated on the day it lands
/// there : the revenue counterpart of [monthExpenses].

@ProviderFor(monthRevenues)
final monthRevenuesProvider = MonthRevenuesProvider._();

/// The rules that fall on the selected month, each dated on the day it lands
/// there : the revenue counterpart of [monthExpenses].

final class MonthRevenuesProvider
    extends
        $FunctionalProvider<
          List<RevenueModel>,
          List<RevenueModel>,
          List<RevenueModel>
        >
    with $Provider<List<RevenueModel>> {
  /// The rules that fall on the selected month, each dated on the day it lands
  /// there : the revenue counterpart of [monthExpenses].
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

String _$monthRevenuesHash() => r'29763dea45e1b5c160562307699e4e4d666fad0d';

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

String _$monthlyRevenuesHash() => r'b89eecd53b9cf9821488f73c0994fd7a4149f115';

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
    r'6ad5b8aa799b65b1f25ed3767aa5d3feaaa04739';

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
