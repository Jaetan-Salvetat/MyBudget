// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le flow local, gardé en vie : le classifieur de lignes et le moteur de
/// reconnaissance coûtent plus cher à recréer qu'à garder.

@ProviderFor(localReceiptScanner)
final localReceiptScannerProvider = LocalReceiptScannerProvider._();

/// Le flow local, gardé en vie : le classifieur de lignes et le moteur de
/// reconnaissance coûtent plus cher à recréer qu'à garder.

final class LocalReceiptScannerProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalReceiptScanner>,
          LocalReceiptScanner,
          FutureOr<LocalReceiptScanner>
        >
    with
        $FutureModifier<LocalReceiptScanner>,
        $FutureProvider<LocalReceiptScanner> {
  /// Le flow local, gardé en vie : le classifieur de lignes et le moteur de
  /// reconnaissance coûtent plus cher à recréer qu'à garder.
  LocalReceiptScannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localReceiptScannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localReceiptScannerHash();

  @$internal
  @override
  $FutureProviderElement<LocalReceiptScanner> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LocalReceiptScanner> create(Ref ref) {
    return localReceiptScanner(ref);
  }
}

String _$localReceiptScannerHash() =>
    r'37cdbb79165d8de7304e400a33255291bde0e27f';

@ProviderFor(receiptScanComposer)
final receiptScanComposerProvider = ReceiptScanComposerProvider._();

final class ReceiptScanComposerProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReceiptScanComposer>,
          ReceiptScanComposer,
          FutureOr<ReceiptScanComposer>
        >
    with
        $FutureModifier<ReceiptScanComposer>,
        $FutureProvider<ReceiptScanComposer> {
  ReceiptScanComposerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptScanComposerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptScanComposerHash();

  @$internal
  @override
  $FutureProviderElement<ReceiptScanComposer> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReceiptScanComposer> create(Ref ref) {
    return receiptScanComposer(ref);
  }
}

String _$receiptScanComposerHash() =>
    r'5929bea723a0e84dc4a8f4004b8f347be224d2ac';

@ProviderFor(ScanNotifier)
final scanProvider = ScanNotifierProvider._();

final class ScanNotifierProvider
    extends
        $NotifierProvider<ScanNotifier, AsyncValue<ReceiptScanResultModel?>> {
  ScanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanNotifierHash();

  @$internal
  @override
  ScanNotifier create() => ScanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ReceiptScanResultModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ReceiptScanResultModel?>>(
        value,
      ),
    );
  }
}

String _$scanNotifierHash() => r'4e25729069aa76fa089b0d26b5f2c101d727447a';

abstract class _$ScanNotifier
    extends $Notifier<AsyncValue<ReceiptScanResultModel?>> {
  AsyncValue<ReceiptScanResultModel?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ReceiptScanResultModel?>,
              AsyncValue<ReceiptScanResultModel?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ReceiptScanResultModel?>,
                AsyncValue<ReceiptScanResultModel?>
              >,
              AsyncValue<ReceiptScanResultModel?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
