// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le flow local, gardé en vie : les modèles de lignes et le moteur de
/// reconnaissance coûtent plus cher à recréer qu'à garder.

@ProviderFor(localReceiptScanner)
final localReceiptScannerProvider = LocalReceiptScannerProvider._();

/// Le flow local, gardé en vie : les modèles de lignes et le moteur de
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
  /// Le flow local, gardé en vie : les modèles de lignes et le moteur de
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
    r'6f850866bb4ef295d6e97c6aee66ea841baaba24';

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

/// La trace de la dernière lecture, pour l'inspecteur de scan.
///
/// Délibérément hors de [ReceiptScanResultModel] : le modèle décrit ce que
/// l'utilisateur valide, la trace explique comment on y est arrivé. Les mêler
/// ferait voyager des détails de pipeline jusque dans la création de dépense.
///
/// Gardée en vie : elle est écrite pendant le scan, alors que personne ne
/// l'écoute — l'inspecteur ne s'ouvre qu'après. Auto-disposée, elle serait
/// détruite dans la foulée et l'écran n'aurait jamais rien à montrer. Ce
/// qu'elle retient est la dernière lecture, remplacée au scan suivant.

@ProviderFor(ScanTrace)
final scanTraceProvider = ScanTraceProvider._();

/// La trace de la dernière lecture, pour l'inspecteur de scan.
///
/// Délibérément hors de [ReceiptScanResultModel] : le modèle décrit ce que
/// l'utilisateur valide, la trace explique comment on y est arrivé. Les mêler
/// ferait voyager des détails de pipeline jusque dans la création de dépense.
///
/// Gardée en vie : elle est écrite pendant le scan, alors que personne ne
/// l'écoute — l'inspecteur ne s'ouvre qu'après. Auto-disposée, elle serait
/// détruite dans la foulée et l'écran n'aurait jamais rien à montrer. Ce
/// qu'elle retient est la dernière lecture, remplacée au scan suivant.
final class ScanTraceProvider
    extends $NotifierProvider<ScanTrace, List<ReadTrace>> {
  /// La trace de la dernière lecture, pour l'inspecteur de scan.
  ///
  /// Délibérément hors de [ReceiptScanResultModel] : le modèle décrit ce que
  /// l'utilisateur valide, la trace explique comment on y est arrivé. Les mêler
  /// ferait voyager des détails de pipeline jusque dans la création de dépense.
  ///
  /// Gardée en vie : elle est écrite pendant le scan, alors que personne ne
  /// l'écoute — l'inspecteur ne s'ouvre qu'après. Auto-disposée, elle serait
  /// détruite dans la foulée et l'écran n'aurait jamais rien à montrer. Ce
  /// qu'elle retient est la dernière lecture, remplacée au scan suivant.
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

/// La trace de la dernière lecture, pour l'inspecteur de scan.
///
/// Délibérément hors de [ReceiptScanResultModel] : le modèle décrit ce que
/// l'utilisateur valide, la trace explique comment on y est arrivé. Les mêler
/// ferait voyager des détails de pipeline jusque dans la création de dépense.
///
/// Gardée en vie : elle est écrite pendant le scan, alors que personne ne
/// l'écoute — l'inspecteur ne s'ouvre qu'après. Auto-disposée, elle serait
/// détruite dans la foulée et l'écran n'aurait jamais rien à montrer. Ce
/// qu'elle retient est la dernière lecture, remplacée au scan suivant.

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

String _$scanNotifierHash() => r'f9aff8b80ccd913e96b363ec9b8ef7fdf527d135';

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
