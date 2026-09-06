// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gemini_nano_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GeminiNanoScanNotifier)
final geminiNanoScanProvider = GeminiNanoScanNotifierProvider._();

final class GeminiNanoScanNotifierProvider
    extends $NotifierProvider<GeminiNanoScanNotifier, bool> {
  GeminiNanoScanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiNanoScanProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiNanoScanNotifierHash();

  @$internal
  @override
  GeminiNanoScanNotifier create() => GeminiNanoScanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$geminiNanoScanNotifierHash() =>
    r'76baa3f3a602a7c74e6c7e656294a3c474ce71ac';

abstract class _$GeminiNanoScanNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(GeminiNanoDownloadNotifier)
final geminiNanoDownloadProvider = GeminiNanoDownloadNotifierProvider._();

final class GeminiNanoDownloadNotifierProvider
    extends $NotifierProvider<GeminiNanoDownloadNotifier, GeminiNanoDownload?> {
  GeminiNanoDownloadNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiNanoDownloadProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiNanoDownloadNotifierHash();

  @$internal
  @override
  GeminiNanoDownloadNotifier create() => GeminiNanoDownloadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeminiNanoDownload? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeminiNanoDownload?>(value),
    );
  }
}

String _$geminiNanoDownloadNotifierHash() =>
    r'794e0891d1b870b9d54f59e25083758d138267c8';

abstract class _$GeminiNanoDownloadNotifier
    extends $Notifier<GeminiNanoDownload?> {
  GeminiNanoDownload? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GeminiNanoDownload?, GeminiNanoDownload?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GeminiNanoDownload?, GeminiNanoDownload?>,
              GeminiNanoDownload?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
