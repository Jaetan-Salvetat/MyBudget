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

String _$quickAddEngineHash() => r'c1c3e075e9180e35119dd7b0dabd6e97f986d23d';

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

String _$quickAddWarmUpHash() => r'ba11bedb4d9548c2b2d8f3a74d79d80b23b22167';
