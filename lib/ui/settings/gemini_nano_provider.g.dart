// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gemini_nano_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'3824d920e7bfdcf36f70678586f3c8eca0034523';

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
