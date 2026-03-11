// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_queries.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeLoans)
final activeLoansProvider = ActiveLoansProvider._();

final class ActiveLoansProvider
    extends $FunctionalProvider<List<Loan>, List<Loan>, List<Loan>>
    with $Provider<List<Loan>> {
  ActiveLoansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeLoansProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeLoansHash();

  @$internal
  @override
  $ProviderElement<List<Loan>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Loan> create(Ref ref) {
    return activeLoans(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Loan> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Loan>>(value),
    );
  }
}

String _$activeLoansHash() => r'6c1e1907f344d4396ddac874b6406f8169abf732';

@ProviderFor(totalMonthlyLoanPayments)
final totalMonthlyLoanPaymentsProvider = TotalMonthlyLoanPaymentsProvider._();

final class TotalMonthlyLoanPaymentsProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  TotalMonthlyLoanPaymentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalMonthlyLoanPaymentsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalMonthlyLoanPaymentsHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return totalMonthlyLoanPayments(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$totalMonthlyLoanPaymentsHash() =>
    r'0ea04cbf7b3a38239c5074db901da2918a614053';

@ProviderFor(totalRemainingLoanAmount)
final totalRemainingLoanAmountProvider = TotalRemainingLoanAmountProvider._();

final class TotalRemainingLoanAmountProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  TotalRemainingLoanAmountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalRemainingLoanAmountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalRemainingLoanAmountHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return totalRemainingLoanAmount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$totalRemainingLoanAmountHash() =>
    r'7ed19a1f408a92f3ef3475ab7d0172840e7dad9f';

@ProviderFor(totalRemainingLoanCost)
final totalRemainingLoanCostProvider = TotalRemainingLoanCostProvider._();

final class TotalRemainingLoanCostProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  TotalRemainingLoanCostProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalRemainingLoanCostProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalRemainingLoanCostHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return totalRemainingLoanCost(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$totalRemainingLoanCostHash() =>
    r'f69134727a72a98a519b7f2c49e18b4c46a46f11';

@ProviderFor(overallLoanProgressPercentage)
final overallLoanProgressPercentageProvider =
    OverallLoanProgressPercentageProvider._();

final class OverallLoanProgressPercentageProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  OverallLoanProgressPercentageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overallLoanProgressPercentageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overallLoanProgressPercentageHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return overallLoanProgressPercentage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$overallLoanProgressPercentageHash() =>
    r'9cd8e54d0bdb8e11e3fe8dfefe4cd65762aceeb0';
