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
    extends
        $AsyncNotifierProvider<BeneficiaryNotifier, List<BeneficiaryModel>> {
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
    r'877809b963fe86d92ec364b305b9bebbaa65dfe2';

abstract class _$BeneficiaryNotifier
    extends $AsyncNotifier<List<BeneficiaryModel>> {
  FutureOr<List<BeneficiaryModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
