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

String _$monthlyRevenuesHash() => r'9b3e4f0ab21d7b071b7ada5cd278a4621fb75afb';

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

String _$upcomingRevenuesHash() => r'f2675e0266e4e906d8f0d08352a87b3b2253a45f';
