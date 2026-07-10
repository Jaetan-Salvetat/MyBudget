// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuickAddNotifier)
final quickAddProvider = QuickAddNotifierProvider._();

final class QuickAddNotifierProvider
    extends
        $NotifierProvider<QuickAddNotifier, AsyncValue<QuickAddResultModel?>> {
  QuickAddNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddNotifierHash();

  @$internal
  @override
  QuickAddNotifier create() => QuickAddNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<QuickAddResultModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<QuickAddResultModel?>>(
        value,
      ),
    );
  }
}

String _$quickAddNotifierHash() => r'e26904b36c2c8ddd61afc85ff8d0e9065ca254a5';

abstract class _$QuickAddNotifier
    extends $Notifier<AsyncValue<QuickAddResultModel?>> {
  AsyncValue<QuickAddResultModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<QuickAddResultModel?>,
              AsyncValue<QuickAddResultModel?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<QuickAddResultModel?>,
                AsyncValue<QuickAddResultModel?>
              >,
              AsyncValue<QuickAddResultModel?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
