// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_reader_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localReceiptScanner)
final localReceiptScannerProvider = LocalReceiptScannerProvider._();

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
    r'a6fc58ad8a890a40d5aa30461e061ed0715fda4a';

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
    r'8a3b6591dd87079a203a99e5a4a27844c5b86563';

@ProviderFor(nanoReceiptReader)
final nanoReceiptReaderProvider = NanoReceiptReaderProvider._();

final class NanoReceiptReaderProvider
    extends
        $FunctionalProvider<
          NanoReceiptReader?,
          NanoReceiptReader?,
          NanoReceiptReader?
        >
    with $Provider<NanoReceiptReader?> {
  NanoReceiptReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nanoReceiptReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nanoReceiptReaderHash();

  @$internal
  @override
  $ProviderElement<NanoReceiptReader?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NanoReceiptReader? create(Ref ref) {
    return nanoReceiptReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NanoReceiptReader? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NanoReceiptReader?>(value),
    );
  }
}

String _$nanoReceiptReaderHash() => r'd81fd5567b34fcb2bf1829e7d75c69e92ba83a5c';

@ProviderFor(cloudScanSelected)
final cloudScanSelectedProvider = CloudScanSelectedProvider._();

final class CloudScanSelectedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  CloudScanSelectedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudScanSelectedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudScanSelectedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return cloudScanSelected(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cloudScanSelectedHash() => r'f6df0de2cc35a7d8cdad289942effa09d00def06';

@ProviderFor(cloudReceiptReader)
final cloudReceiptReaderProvider = CloudReceiptReaderProvider._();

final class CloudReceiptReaderProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudReceiptReader?>,
          CloudReceiptReader?,
          FutureOr<CloudReceiptReader?>
        >
    with
        $FutureModifier<CloudReceiptReader?>,
        $FutureProvider<CloudReceiptReader?> {
  CloudReceiptReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudReceiptReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudReceiptReaderHash();

  @$internal
  @override
  $FutureProviderElement<CloudReceiptReader?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudReceiptReader?> create(Ref ref) {
    return cloudReceiptReader(ref);
  }
}

String _$cloudReceiptReaderHash() =>
    r'c3f1b1a9d533424f8f2ebae707bb5af8299722f8';
