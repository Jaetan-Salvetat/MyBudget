// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loans_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoanNotifier)
const loanProvider = LoanNotifierProvider._();

final class LoanNotifierProvider
    extends $AsyncNotifierProvider<LoanNotifier, List<Loan>> {
  const LoanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanNotifierHash();

  @$internal
  @override
  LoanNotifier create() => LoanNotifier();
}

String _$loanNotifierHash() => r'73b0caeea50849867c8dfc34bd6bc50d9ecac5c7';

abstract class _$LoanNotifier extends $AsyncNotifier<List<Loan>> {
  FutureOr<List<Loan>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Loan>>, List<Loan>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Loan>>, List<Loan>>,
              AsyncValue<List<Loan>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
