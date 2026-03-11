// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loans_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoanNotifier)
final loanProvider = LoanNotifierProvider._();

final class LoanNotifierProvider
    extends $AsyncNotifierProvider<LoanNotifier, List<Loan>> {
  LoanNotifierProvider._()
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

String _$loanNotifierHash() => r'e6d46c1849ae7df9e81635cc0d5fac1f18cd1538';

abstract class _$LoanNotifier extends $AsyncNotifier<List<Loan>> {
  FutureOr<List<Loan>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Loan>>, List<Loan>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Loan>>, List<Loan>>,
              AsyncValue<List<Loan>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
