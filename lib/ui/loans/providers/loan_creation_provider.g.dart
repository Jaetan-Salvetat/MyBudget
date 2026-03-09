// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_creation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoanCreationNotifier)
const loanCreationProvider = LoanCreationNotifierProvider._();

final class LoanCreationNotifierProvider
    extends $NotifierProvider<LoanCreationNotifier, LoanCreationState> {
  const LoanCreationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanCreationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanCreationNotifierHash();

  @$internal
  @override
  LoanCreationNotifier create() => LoanCreationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanCreationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanCreationState>(value),
    );
  }
}

String _$loanCreationNotifierHash() =>
    r'da20fdd626bb2e9c0037e01c66dbf68d3ed7a9fe';

abstract class _$LoanCreationNotifier extends $Notifier<LoanCreationState> {
  LoanCreationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LoanCreationState, LoanCreationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoanCreationState, LoanCreationState>,
              LoanCreationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
