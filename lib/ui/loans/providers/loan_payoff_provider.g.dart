// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_payoff_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(loanToPayoff)
final loanToPayoffProvider = LoanToPayoffProvider._();

final class LoanToPayoffProvider extends $FunctionalProvider<Loan, Loan, Loan>
    with $Provider<Loan> {
  LoanToPayoffProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanToPayoffProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanToPayoffHash();

  @$internal
  @override
  $ProviderElement<Loan> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Loan create(Ref ref) {
    return loanToPayoff(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Loan value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Loan>(value),
    );
  }
}

String _$loanToPayoffHash() => r'58d8cee86ccd8400a7b4012b8a64cdc29b73c40e';

@ProviderFor(LoanPayoffNotifier)
final loanPayoffProvider = LoanPayoffNotifierProvider._();

final class LoanPayoffNotifierProvider
    extends $NotifierProvider<LoanPayoffNotifier, LoanPayoffState> {
  LoanPayoffNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanPayoffProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[loanToPayoffProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          LoanPayoffNotifierProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = loanToPayoffProvider;

  @override
  String debugGetCreateSourceHash() => _$loanPayoffNotifierHash();

  @$internal
  @override
  LoanPayoffNotifier create() => LoanPayoffNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanPayoffState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanPayoffState>(value),
    );
  }
}

String _$loanPayoffNotifierHash() =>
    r'c244b330776c28feaf0deab9ef079f9baaf0212c';

abstract class _$LoanPayoffNotifier extends $Notifier<LoanPayoffState> {
  LoanPayoffState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LoanPayoffState, LoanPayoffState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoanPayoffState, LoanPayoffState>,
              LoanPayoffState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
