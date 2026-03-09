// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_edit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider de paramètre : expose le prêt à éditer.
/// Surchargé via ProviderScope override dans LoanEditBottomSheet.show().

@ProviderFor(loanToEdit)
const loanToEditProvider = LoanToEditProvider._();

/// Provider de paramètre : expose le prêt à éditer.
/// Surchargé via ProviderScope override dans LoanEditBottomSheet.show().

final class LoanToEditProvider extends $FunctionalProvider<Loan, Loan, Loan>
    with $Provider<Loan> {
  /// Provider de paramètre : expose le prêt à éditer.
  /// Surchargé via ProviderScope override dans LoanEditBottomSheet.show().
  const LoanToEditProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanToEditProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanToEditHash();

  @$internal
  @override
  $ProviderElement<Loan> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Loan create(Ref ref) {
    return loanToEdit(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Loan value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Loan>(value),
    );
  }
}

String _$loanToEditHash() => r'9fc60950f99cb9d90418fb5292f6b9537bb0ac87';

@ProviderFor(LoanEditNotifier)
const loanEditProvider = LoanEditNotifierProvider._();

final class LoanEditNotifierProvider
    extends $NotifierProvider<LoanEditNotifier, LoanEditState> {
  const LoanEditNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanEditProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanEditNotifierHash();

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
}

String _$loanEditNotifierHash() => r'619311cd4b92836a7d441d3b4ed4d174a07ae19f';

abstract class _$LoanEditNotifier extends $Notifier<LoanEditState> {
  LoanEditState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LoanEditState, LoanEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoanEditState, LoanEditState>,
              LoanEditState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
