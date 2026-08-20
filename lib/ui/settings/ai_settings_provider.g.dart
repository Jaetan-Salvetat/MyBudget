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
