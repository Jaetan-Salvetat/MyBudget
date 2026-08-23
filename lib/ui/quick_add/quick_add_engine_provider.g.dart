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

String _$quickAddEngineHash() => r'8f7ca788fcd6d88dd9be6292534704ea7443c88f';

/// Le moteur se chargeait au premier caractere tape : le modele et le
/// tokenizer arrivaient pendant que l'utilisateur attendait sa categorie.
/// Le declencher au splash sort ce cout du chemin critique — l'ecran dure
/// deja plus longtemps que le chargement.
///
/// Un echec ne remonte pas : l'ajout rapide n'est pas ce qui doit empecher
/// l'app de demarrer, et l'erreur se represente d'elle-meme au premier usage.

@ProviderFor(quickAddWarmUp)
final quickAddWarmUpProvider = QuickAddWarmUpProvider._();

/// Le moteur se chargeait au premier caractere tape : le modele et le
/// tokenizer arrivaient pendant que l'utilisateur attendait sa categorie.
/// Le declencher au splash sort ce cout du chemin critique — l'ecran dure
/// deja plus longtemps que le chargement.
///
/// Un echec ne remonte pas : l'ajout rapide n'est pas ce qui doit empecher
/// l'app de demarrer, et l'erreur se represente d'elle-meme au premier usage.

final class QuickAddWarmUpProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Le moteur se chargeait au premier caractere tape : le modele et le
  /// tokenizer arrivaient pendant que l'utilisateur attendait sa categorie.
  /// Le declencher au splash sort ce cout du chemin critique — l'ecran dure
  /// deja plus longtemps que le chargement.
  ///
  /// Un echec ne remonte pas : l'ajout rapide n'est pas ce qui doit empecher
  /// l'app de demarrer, et l'erreur se represente d'elle-meme au premier usage.
  QuickAddWarmUpProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddWarmUpProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddWarmUpHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return quickAddWarmUp(ref);
  }
}

String _$quickAddWarmUpHash() => r'5605a998379aea0cf1d19d6f2ae25631db388c19';
