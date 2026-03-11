// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(netCashFlow)
final netCashFlowProvider = NetCashFlowProvider._();

final class NetCashFlowProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  NetCashFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'netCashFlowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$netCashFlowHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return netCashFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$netCashFlowHash() => r'8769975001ecc38eb8a5ec2b7155d6495e24db0f';

@ProviderFor(savingsRate)
final savingsRateProvider = SavingsRateProvider._();

final class SavingsRateProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  SavingsRateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savingsRateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savingsRateHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return savingsRate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$savingsRateHash() => r'0027a17b0292cee36a77b2c70997e34a6d3ab50b';

@ProviderFor(totalMonthlyOutflows)
final totalMonthlyOutflowsProvider = TotalMonthlyOutflowsProvider._();

final class TotalMonthlyOutflowsProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  TotalMonthlyOutflowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalMonthlyOutflowsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalMonthlyOutflowsHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return totalMonthlyOutflows(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$totalMonthlyOutflowsHash() =>
    r'a3af5fb8d1610456f92dd419c3ffc18f930ec5fe';
