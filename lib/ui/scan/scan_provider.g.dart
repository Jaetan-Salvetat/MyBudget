// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$scanNotifierHash() => r'90f18e1928595f83f309770408262632793a0ab8';

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
