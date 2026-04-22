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
    extends $AsyncNotifierProvider<TransferNotifier, List<Transfer>> {
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

String _$transferNotifierHash() => r'0ee6001cb2101835ba90b3de5b6656a67ba21274';

abstract class _$TransferNotifier extends $AsyncNotifier<List<Transfer>> {
  FutureOr<List<Transfer>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Transfer>>, List<Transfer>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Transfer>>, List<Transfer>>,
              AsyncValue<List<Transfer>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
