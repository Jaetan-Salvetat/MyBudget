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

String _$loanNotifierHash() => r'745a1612eb8c27169f35b3492e0de53197e1acf2';

abstract class _$LoanNotifier extends $AsyncNotifier<List<Loan>> {
  FutureOr<List<Loan>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Loan>>, List<Loan>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Loan>>, List<Loan>>,
              AsyncValue<List<Loan>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
