// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le service de scan, ou rien quand aucune clé ne peut le servir. Il partage
/// le fournisseur, le modèle et la clé de l'ajout rapide. Gardé en vie le
/// temps d'un scan : le client HTTP se fermerait sous la requête en cours.

@ProviderFor(receiptScanService)
final receiptScanServiceProvider = ReceiptScanServiceProvider._();

/// Le service de scan, ou rien quand aucune clé ne peut le servir. Il partage
/// le fournisseur, le modèle et la clé de l'ajout rapide. Gardé en vie le
/// temps d'un scan : le client HTTP se fermerait sous la requête en cours.

final class ReceiptScanServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReceiptScanService?>,
          ReceiptScanService?,
          FutureOr<ReceiptScanService?>
        >
    with
        $FutureModifier<ReceiptScanService?>,
        $FutureProvider<ReceiptScanService?> {
  /// Le service de scan, ou rien quand aucune clé ne peut le servir. Il partage
  /// le fournisseur, le modèle et la clé de l'ajout rapide. Gardé en vie le
  /// temps d'un scan : le client HTTP se fermerait sous la requête en cours.
  ReceiptScanServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptScanServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptScanServiceHash();

  @$internal
  @override
  $FutureProviderElement<ReceiptScanService?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReceiptScanService?> create(Ref ref) {
    return receiptScanService(ref);
  }
}

String _$receiptScanServiceHash() =>
    r'95dfcd6e87cf3c0e6be842353bcec691b0a0b41a';

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

String _$scanNotifierHash() => r'0cb72e6ace2fc5ed7d15e6f3623c6549e1b578d1';

abstract class _$ScanNotifier
    extends $Notifier<AsyncValue<ReceiptScanResultModel?>> {
  AsyncValue<ReceiptScanResultModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
