// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beneficiary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BeneficiaryNotifier)
const beneficiaryProvider = BeneficiaryNotifierProvider._();

final class BeneficiaryNotifierProvider
    extends
        $AsyncNotifierProvider<BeneficiaryNotifier, List<BeneficiaryModel>> {
  const BeneficiaryNotifierProvider._()
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
    r'8545dab77955374fdcd69931466d16e12a435388';

abstract class _$BeneficiaryNotifier
    extends $AsyncNotifier<List<BeneficiaryModel>> {
  FutureOr<List<BeneficiaryModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<BeneficiaryModel>>, List<BeneficiaryModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<BeneficiaryModel>>,
                List<BeneficiaryModel>
              >,
              AsyncValue<List<BeneficiaryModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
