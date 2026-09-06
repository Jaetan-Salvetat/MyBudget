// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(featureFlagRegistry)
final featureFlagRegistryProvider = FeatureFlagRegistryProvider._();

final class FeatureFlagRegistryProvider
    extends
        $FunctionalProvider<
          List<FeatureFlag>,
          List<FeatureFlag>,
          List<FeatureFlag>
        >
    with $Provider<List<FeatureFlag>> {
  FeatureFlagRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureFlagRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureFlagRegistryHash();

  @$internal
  @override
  $ProviderElement<List<FeatureFlag>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FeatureFlag> create(Ref ref) {
    return featureFlagRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FeatureFlag> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FeatureFlag>>(value),
    );
  }
}

String _$featureFlagRegistryHash() =>
    r'abb95a720450d293ba3db73ef2394059290d86c6';

@ProviderFor(flagBlocklistService)
final flagBlocklistServiceProvider = FlagBlocklistServiceProvider._();

final class FlagBlocklistServiceProvider
    extends
        $FunctionalProvider<
          FlagBlocklistService,
          FlagBlocklistService,
          FlagBlocklistService
        >
    with $Provider<FlagBlocklistService> {
  FlagBlocklistServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flagBlocklistServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flagBlocklistServiceHash();

  @$internal
  @override
  $ProviderElement<FlagBlocklistService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlagBlocklistService create(Ref ref) {
    return flagBlocklistService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlagBlocklistService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlagBlocklistService>(value),
    );
  }
}

String _$flagBlocklistServiceHash() =>
    r'5a9fbd4c8a97d80735c33f846a640dbcada70669';

@ProviderFor(FlagBlocklistNotifier)
final flagBlocklistProvider = FlagBlocklistNotifierProvider._();

final class FlagBlocklistNotifierProvider
    extends $NotifierProvider<FlagBlocklistNotifier, FlagBlocklist> {
  FlagBlocklistNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flagBlocklistProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flagBlocklistNotifierHash();

  @$internal
  @override
  FlagBlocklistNotifier create() => FlagBlocklistNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlagBlocklist value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlagBlocklist>(value),
    );
  }
}

String _$flagBlocklistNotifierHash() =>
    r'f6267cd795b4a4399ae44c23988ac94cd68f1bd8';

abstract class _$FlagBlocklistNotifier extends $Notifier<FlagBlocklist> {
  FlagBlocklist build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FlagBlocklist, FlagBlocklist>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FlagBlocklist, FlagBlocklist>,
              FlagBlocklist,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FeatureFlagChoicesNotifier)
final featureFlagChoicesProvider = FeatureFlagChoicesNotifierProvider._();

final class FeatureFlagChoicesNotifierProvider
    extends $NotifierProvider<FeatureFlagChoicesNotifier, Map<String, bool>> {
  FeatureFlagChoicesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureFlagChoicesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureFlagChoicesNotifierHash();

  @$internal
  @override
  FeatureFlagChoicesNotifier create() => FeatureFlagChoicesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$featureFlagChoicesNotifierHash() =>
    r'a0c4e696ff532f62002d145a57266fe071410202';

abstract class _$FeatureFlagChoicesNotifier
    extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(featureFlagResolver)
final featureFlagResolverProvider = FeatureFlagResolverProvider._();

final class FeatureFlagResolverProvider
    extends
        $FunctionalProvider<
          FeatureFlagResolver,
          FeatureFlagResolver,
          FeatureFlagResolver
        >
    with $Provider<FeatureFlagResolver> {
  FeatureFlagResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureFlagResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureFlagResolverHash();

  @$internal
  @override
  $ProviderElement<FeatureFlagResolver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeatureFlagResolver create(Ref ref) {
    return featureFlagResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeatureFlagResolver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeatureFlagResolver>(value),
    );
  }
}

String _$featureFlagResolverHash() =>
    r'2e6f0d14bc7eab5aa48778ada30f90801028102c';

@ProviderFor(featureEnabled)
final featureEnabledProvider = FeatureEnabledFamily._();

final class FeatureEnabledProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  FeatureEnabledProvider._({
    required FeatureEnabledFamily super.from,
    required FeatureFlag super.argument,
  }) : super(
         retry: null,
         name: r'featureEnabledProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$featureEnabledHash();

  @override
  String toString() {
    return r'featureEnabledProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as FeatureFlag;
    return featureEnabled(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureEnabledProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$featureEnabledHash() => r'67f570dee10d7052f47c2d7056b8e232cd4c0ee6';

final class FeatureEnabledFamily extends $Family
    with $FunctionalFamilyOverride<bool, FeatureFlag> {
  FeatureEnabledFamily._()
    : super(
        retry: null,
        name: r'featureEnabledProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  FeatureEnabledProvider call(FeatureFlag flag) =>
      FeatureEnabledProvider._(argument: flag, from: this);

  @override
  String toString() => r'featureEnabledProvider';
}

@ProviderFor(featureBlocked)
final featureBlockedProvider = FeatureBlockedFamily._();

final class FeatureBlockedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  FeatureBlockedProvider._({
    required FeatureBlockedFamily super.from,
    required FeatureFlag super.argument,
  }) : super(
         retry: null,
         name: r'featureBlockedProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$featureBlockedHash();

  @override
  String toString() {
    return r'featureBlockedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as FeatureFlag;
    return featureBlocked(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureBlockedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$featureBlockedHash() => r'a29e10b973966ca1926b59868111738228dd9268';

final class FeatureBlockedFamily extends $Family
    with $FunctionalFamilyOverride<bool, FeatureFlag> {
  FeatureBlockedFamily._()
    : super(
        retry: null,
        name: r'featureBlockedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  FeatureBlockedProvider call(FeatureFlag flag) =>
      FeatureBlockedProvider._(argument: flag, from: this);

  @override
  String toString() => r'featureBlockedProvider';
}
