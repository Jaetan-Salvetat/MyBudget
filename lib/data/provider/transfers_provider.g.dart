// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransferNotifier)
final transferProvider = TransferNotifierProvider._();

final class TransferNotifierProvider
    extends $AsyncNotifierProvider<TransferNotifier, List<TransferModel>> {
  TransferNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferNotifierHash();

  @$internal
  @override
  TransferNotifier create() => TransferNotifier();
}

String _$transferNotifierHash() => r'96954e75eedaf52bc421ed0f5c333e3681b87b77';

abstract class _$TransferNotifier extends $AsyncNotifier<List<TransferModel>> {
  FutureOr<List<TransferModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TransferModel>>, List<TransferModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TransferModel>>, List<TransferModel>>,
              AsyncValue<List<TransferModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
