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
    r'c2cc0fd2c7d32cfd1a392270e2c74d631bc56d20';

abstract class _$BeneficiaryNotifier extends $AsyncNotifier<List<Beneficiary>> {
  FutureOr<List<Beneficiary>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
