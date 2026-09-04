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

@ProviderFor(QuickAddEngineModeNotifier)
final quickAddEngineModeProvider = QuickAddEngineModeNotifierProvider._();

final class QuickAddEngineModeNotifierProvider
    extends $NotifierProvider<QuickAddEngineModeNotifier, QuickAddEngineMode> {
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

abstract class _$QuickAddEngineModeNotifier
    extends $Notifier<QuickAddEngineMode> {
  QuickAddEngineMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuickAddEngineMode, QuickAddEngineMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickAddEngineMode, QuickAddEngineMode>,
              QuickAddEngineMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AiProvider, AiProvider>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiProvider, AiProvider>,
              AiProvider,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedAiModelNotifier)
final selectedAiModelProvider = SelectedAiModelNotifierProvider._();

final class SelectedAiModelNotifierProvider
    extends $NotifierProvider<SelectedAiModelNotifier, AiModel> {
  SelectedAiModelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedAiModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedAiModelNotifierHash();

  @$internal
  @override
  SelectedAiModelNotifier create() => SelectedAiModelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiModel>(value),
    );
  }
}

String _$selectedAiModelNotifierHash() =>
    r'b996ee92726a2001f3b0ec29a90b1d8d420ff1e2';

abstract class _$SelectedAiModelNotifier extends $Notifier<AiModel> {
  AiModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AiModel, AiModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiModel, AiModel>,
              AiModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(hasStoredApiKey)
final hasStoredApiKeyProvider = HasStoredApiKeyProvider._();

final class HasStoredApiKeyProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
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

@ProviderFor(quickAddUsesRemote)
final quickAddUsesRemoteProvider = QuickAddUsesRemoteProvider._();

final class QuickAddUsesRemoteProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  QuickAddUsesRemoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddUsesRemoteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddUsesRemoteHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return quickAddUsesRemote(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$quickAddUsesRemoteHash() =>
    r'c8253f478134f8b54c256a7e6b8d7a6b1fb6ea3c';
