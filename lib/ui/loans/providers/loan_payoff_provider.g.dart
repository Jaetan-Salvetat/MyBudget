// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_payoff_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoanPayoffNotifier)
final loanPayoffProvider = LoanPayoffNotifierFamily._();

final class LoanPayoffNotifierProvider
    extends $NotifierProvider<LoanPayoffNotifier, LoanPayoffState> {
  LoanPayoffNotifierProvider._({
    required LoanPayoffNotifierFamily super.from,
    required Loan super.argument,
  }) : super(
         retry: null,
         name: r'loanPayoffProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loanPayoffNotifierHash();

  @override
  String toString() {
    return r'loanPayoffProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is LoanPayoffNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loanPayoffNotifierHash() =>
    r'579052a5be49adb8adbaecd90fd8d369a0752fe5';

final class LoanPayoffNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          LoanPayoffNotifier,
          LoanPayoffState,
          LoanPayoffState,
          LoanPayoffState,
          Loan
        > {
  LoanPayoffNotifierFamily._()
    : super(
        retry: null,
        name: r'loanPayoffProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LoanPayoffNotifierProvider call(Loan loan) =>
      LoanPayoffNotifierProvider._(argument: loan, from: this);

  @override
  String toString() => r'loanPayoffProvider';
}

abstract class _$LoanPayoffNotifier extends $Notifier<LoanPayoffState> {
  late final _$args = ref.$arg as Loan;
  Loan get loan => _$args;

  LoanPayoffState build(Loan loan);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LoanPayoffState, LoanPayoffState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoanPayoffState, LoanPayoffState>,
              LoanPayoffState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
