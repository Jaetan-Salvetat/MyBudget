// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Compose le moteur effectif. Toute raison de ne pas pouvoir appeler le
/// distant — pas de clé, moteur dégradé, mode local — redonne simplement le
/// moteur embarqué : l'ajout rapide n'a aucun état où il ne marche pas.

@ProviderFor(quickAddEngine)
final quickAddEngineProvider = QuickAddEngineProvider._();

/// Compose le moteur effectif. Toute raison de ne pas pouvoir appeler le
/// distant — pas de clé, moteur dégradé, mode local — redonne simplement le
/// moteur embarqué : l'ajout rapide n'a aucun état où il ne marche pas.

final class QuickAddEngineProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuickAddEngine>,
          QuickAddEngine,
          FutureOr<QuickAddEngine>
        >
    with $FutureModifier<QuickAddEngine>, $FutureProvider<QuickAddEngine> {
  /// Compose le moteur effectif. Toute raison de ne pas pouvoir appeler le
  /// distant — pas de clé, moteur dégradé, mode local — redonne simplement le
  /// moteur embarqué : l'ajout rapide n'a aucun état où il ne marche pas.
  QuickAddEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddEngineHash();

  @$internal
  @override
  $FutureProviderElement<QuickAddEngine> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuickAddEngine> create(Ref ref) {
    return quickAddEngine(ref);
  }
}

String _$quickAddEngineHash() => r'c821942049fa6303b917f4ca53e7d113a35af188';
