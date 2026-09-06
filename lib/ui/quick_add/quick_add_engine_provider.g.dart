// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(quickAddEngine)
final quickAddEngineProvider = QuickAddEngineProvider._();

final class QuickAddEngineProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuickAddEngine>,
          QuickAddEngine,
          FutureOr<QuickAddEngine>
        >
    with $FutureModifier<QuickAddEngine>, $FutureProvider<QuickAddEngine> {
  QuickAddEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: failFast,
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

String _$quickAddEngineHash() => r'c5dfb1a7ba5f6901777df126950d3c9f4996d59a';

@ProviderFor(quickAddWarmUp)
final quickAddWarmUpProvider = QuickAddWarmUpProvider._();

final class QuickAddWarmUpProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
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
