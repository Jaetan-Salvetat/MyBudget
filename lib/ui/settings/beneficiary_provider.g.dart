// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beneficiary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BeneficiaryNotifier)
final beneficiaryProvider = BeneficiaryNotifierProvider._();

final class BeneficiaryNotifierProvider
    extends $AsyncNotifierProvider<BeneficiaryNotifier, List<Beneficiary>> {
  BeneficiaryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'beneficiaryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$beneficiaryNotifierHash();

  @$internal
  @override
  BeneficiaryNotifier create() => BeneficiaryNotifier();
}

String _$beneficiaryNotifierHash() =>
    r'17cc45f31054a45c3719c3554aad5ab597495353';

abstract class _$BeneficiaryNotifier extends $AsyncNotifier<List<Beneficiary>> {
  FutureOr<List<Beneficiary>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<Beneficiary>>, List<Beneficiary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Beneficiary>>, List<Beneficiary>>,
              AsyncValue<List<Beneficiary>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
