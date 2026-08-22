// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuickAddEnabledNotifier)
final quickAddEnabledProvider = QuickAddEnabledNotifierProvider._();

final class QuickAddEnabledNotifierProvider
    extends $NotifierProvider<QuickAddEnabledNotifier, bool> {
  QuickAddEnabledNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddEnabledNotifierHash();

  @$internal
  @override
  QuickAddEnabledNotifier create() => QuickAddEnabledNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$quickAddEnabledNotifierHash() =>
    r'2064a2e91fd3218c7360d18b5e7ae14414b1f884';

abstract class _$QuickAddEnabledNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Le moteur retenu. Il ne bascule sur [QuickAddEngineMode.apiKey] qu'après une
/// vérification aboutie : cocher l'option ne suffit pas.

@ProviderFor(QuickAddEngineModeNotifier)
final quickAddEngineModeProvider = QuickAddEngineModeNotifierProvider._();

/// Le moteur retenu. Il ne bascule sur [QuickAddEngineMode.apiKey] qu'après une
/// vérification aboutie : cocher l'option ne suffit pas.
final class QuickAddEngineModeNotifierProvider
    extends $NotifierProvider<QuickAddEngineModeNotifier, QuickAddEngineMode> {
  /// Le moteur retenu. Il ne bascule sur [QuickAddEngineMode.apiKey] qu'après une
  /// vérification aboutie : cocher l'option ne suffit pas.
  QuickAddEngineModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddEngineModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddEngineModeNotifierHash();

  @$internal
  @override
  QuickAddEngineModeNotifier create() => QuickAddEngineModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuickAddEngineMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickAddEngineMode>(value),
    );
  }
}

String _$quickAddEngineModeNotifierHash() =>
    r'c7e8ab4c511aba935b4512b4bfeeed2dd822fd38';

/// Le moteur retenu. Il ne bascule sur [QuickAddEngineMode.apiKey] qu'après une
/// vérification aboutie : cocher l'option ne suffit pas.

abstract class _$QuickAddEngineModeNotifier
    extends $Notifier<QuickAddEngineMode> {
  QuickAddEngineMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QuickAddEngineMode, QuickAddEngineMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickAddEngineMode, QuickAddEngineMode>,
              QuickAddEngineMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedAiProviderNotifier)
final selectedAiProviderProvider = SelectedAiProviderNotifierProvider._();

final class SelectedAiProviderNotifierProvider
    extends $NotifierProvider<SelectedAiProviderNotifier, AiProvider> {
  SelectedAiProviderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedAiProviderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedAiProviderNotifierHash();

  @$internal
  @override
  SelectedAiProviderNotifier create() => SelectedAiProviderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiProvider value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiProvider>(value),
    );
  }
}

String _$selectedAiProviderNotifierHash() =>
    r'b6e146af285638d9a3e31e2166f1099e34a67f2d';

abstract class _$SelectedAiProviderNotifier extends $Notifier<AiProvider> {
  AiProvider build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AiProvider, AiProvider>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiProvider, AiProvider>,
              AiProvider,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AiCloudConsentNotifier)
final aiCloudConsentProvider = AiCloudConsentNotifierProvider._();

final class AiCloudConsentNotifierProvider
    extends $NotifierProvider<AiCloudConsentNotifier, bool> {
  AiCloudConsentNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiCloudConsentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiCloudConsentNotifierHash();

  @$internal
  @override
  AiCloudConsentNotifier create() => AiCloudConsentNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$aiCloudConsentNotifierHash() =>
    r'759582579dba269cc6b0ee64075b7d6639d3f7d7';

abstract class _$AiCloudConsentNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Vrai quand la clé du fournisseur courant est dans le trousseau. La clé
/// elle-même ne remonte jamais jusqu'à l'UI.

@ProviderFor(hasStoredApiKey)
final hasStoredApiKeyProvider = HasStoredApiKeyProvider._();

/// Vrai quand la clé du fournisseur courant est dans le trousseau. La clé
/// elle-même ne remonte jamais jusqu'à l'UI.

final class HasStoredApiKeyProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Vrai quand la clé du fournisseur courant est dans le trousseau. La clé
  /// elle-même ne remonte jamais jusqu'à l'UI.
  HasStoredApiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasStoredApiKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasStoredApiKeyHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasStoredApiKey(ref);
  }
}

String _$hasStoredApiKeyHash() => r'c3bd7ffc5feaf55cb2c745b2952d6dfde4661659';

/// L'ajout rapide est-il retombé en local malgré une clé active. Ne passe à
/// vrai qu'une fois : l'utilisateur est prévenu une seule fois.

@ProviderFor(QuickAddDegradationNotifier)
final quickAddDegradationProvider = QuickAddDegradationNotifierProvider._();

/// L'ajout rapide est-il retombé en local malgré une clé active. Ne passe à
/// vrai qu'une fois : l'utilisateur est prévenu une seule fois.
final class QuickAddDegradationNotifierProvider
    extends $NotifierProvider<QuickAddDegradationNotifier, bool> {
  /// L'ajout rapide est-il retombé en local malgré une clé active. Ne passe à
  /// vrai qu'une fois : l'utilisateur est prévenu une seule fois.
  QuickAddDegradationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddDegradationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddDegradationNotifierHash();

  @$internal
  @override
  QuickAddDegradationNotifier create() => QuickAddDegradationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$quickAddDegradationNotifierHash() =>
    r'3dafc99d4f2c62e85748c0429e9dd388d241aef8';

/// L'ajout rapide est-il retombé en local malgré une clé active. Ne passe à
/// vrai qu'une fois : l'utilisateur est prévenu une seule fois.

abstract class _$QuickAddDegradationNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
