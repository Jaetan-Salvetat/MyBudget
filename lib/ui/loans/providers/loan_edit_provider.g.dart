// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_edit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoanEditNotifier)
final loanEditProvider = LoanEditNotifierFamily._();

final class LoanEditNotifierProvider
    extends $NotifierProvider<LoanEditNotifier, LoanEditState> {
  LoanEditNotifierProvider._({
    required LoanEditNotifierFamily super.from,
    required Loan super.argument,
  }) : super(
         retry: null,
         name: r'loanEditProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loanEditNotifierHash();

  @override
  String toString() {
    return r'loanEditProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LoanEditNotifier create() => LoanEditNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanEditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanEditState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LoanEditNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loanEditNotifierHash() => r'215525a545665b90a2c207f4335c69dd3e5299a9';

final class LoanEditNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          LoanEditNotifier,
          LoanEditState,
          LoanEditState,
          LoanEditState,
          Loan
        > {
  LoanEditNotifierFamily._()
    : super(
        retry: null,
        name: r'loanEditProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LoanEditNotifierProvider call(Loan loan) =>
      LoanEditNotifierProvider._(argument: loan, from: this);

  @override
  String toString() => r'loanEditProvider';
}

abstract class _$LoanEditNotifier extends $Notifier<LoanEditState> {
  late final _$args = ref.$arg as Loan;
  Loan get loan => _$args;

  LoanEditState build(Loan loan);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LoanEditState, LoanEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoanEditState, LoanEditState>,
              LoanEditState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
