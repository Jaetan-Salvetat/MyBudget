// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_provider.dart';

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

@ProviderFor(ScanTrace)
final scanTraceProvider = ScanTraceProvider._();

final class ScanTraceProvider
    extends $NotifierProvider<ScanTrace, List<ReadTrace>> {
  ScanTraceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanTraceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanTraceHash();

  @$internal
  @override
  ScanTrace create() => ScanTrace();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ReadTrace> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ReadTrace>>(value),
    );
  }
}

String _$scanTraceHash() => r'a17c846f4cea0bee9f25261cc66d1974bc5e3921';

abstract class _$ScanTrace extends $Notifier<List<ReadTrace>> {
  List<ReadTrace> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<ReadTrace>, List<ReadTrace>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ReadTrace>, List<ReadTrace>>,
              List<ReadTrace>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ScanProgress)
final scanProgressProvider = ScanProgressProvider._();

final class ScanProgressProvider
    extends $NotifierProvider<ScanProgress, ScanReadProgress> {
  ScanProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanProgressHash();

  @$internal
  @override
  ScanProgress create() => ScanProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanReadProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanReadProgress>(value),
    );
  }
}

String _$scanProgressHash() => r'573156719e5ff633fa64539c47a2891229a15c8c';

abstract class _$ScanProgress extends $Notifier<ScanReadProgress> {
  ScanReadProgress build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScanReadProgress, ScanReadProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScanReadProgress, ScanReadProgress>,
              ScanReadProgress,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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

String _$scanNotifierHash() => r'1d6eb6373ecd205f5e5128619fa4f02d855ed11f';

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
