// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$monthlyRevenuesHash() => r'fc027e0d4cbb7c69cac483f3aa917cee8e7c03ef';

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
    r'ef667fa60df2ae5d71ae1df3ae95d48ea093ebce';

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

String _$upcomingRevenuesHash() => r'c9a3014cea6f14205e7dd6688fe71387b85ac2d7';
