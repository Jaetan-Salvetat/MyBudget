// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Total des revenus du mois courant (réguliers + ponctuels).

@ProviderFor(monthlyRevenues)
const monthlyRevenuesProvider = MonthlyRevenuesProvider._();

/// Total des revenus du mois courant (réguliers + ponctuels).

final class MonthlyRevenuesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Total des revenus du mois courant (réguliers + ponctuels).
  const MonthlyRevenuesProvider._()
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

/// Total des revenus réguliers (isRegular = true) du mois courant.

@ProviderFor(monthlyFixedRevenues)
const monthlyFixedRevenuesProvider = MonthlyFixedRevenuesProvider._();

/// Total des revenus réguliers (isRegular = true) du mois courant.

final class MonthlyFixedRevenuesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Total des revenus réguliers (isRegular = true) du mois courant.
  const MonthlyFixedRevenuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyFixedRevenuesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyFixedRevenuesHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return monthlyFixedRevenues(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$monthlyFixedRevenuesHash() =>
    r'7339fcd18cc6319126c8e7ca179f2b9b5a1d774c';

/// Total des revenus ponctuels (isRegular = false) du mois courant.

@ProviderFor(monthlyPunctualRevenues)
const monthlyPunctualRevenuesProvider = MonthlyPunctualRevenuesProvider._();

/// Total des revenus ponctuels (isRegular = false) du mois courant.

final class MonthlyPunctualRevenuesProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Total des revenus ponctuels (isRegular = false) du mois courant.
  const MonthlyPunctualRevenuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyPunctualRevenuesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyPunctualRevenuesHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return monthlyPunctualRevenues(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$monthlyPunctualRevenuesHash() =>
    r'2c109c204a652bc595813cf595268089e0f72b38';
