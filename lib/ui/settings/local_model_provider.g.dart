// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_model_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocalModelNotifier)
final localModelProvider = LocalModelNotifierProvider._();

final class LocalModelNotifierProvider
    extends $NotifierProvider<LocalModelNotifier, LocalModelState> {
  LocalModelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localModelNotifierHash();

  @$internal
  @override
  LocalModelNotifier create() => LocalModelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalModelState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalModelState>(value),
    );
  }
}

String _$localModelNotifierHash() =>
    r'8a1bad659dfc313d8539b53944bc6a0b847019df';

abstract class _$LocalModelNotifier extends $Notifier<LocalModelState> {
  LocalModelState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LocalModelState, LocalModelState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocalModelState, LocalModelState>,
              LocalModelState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
