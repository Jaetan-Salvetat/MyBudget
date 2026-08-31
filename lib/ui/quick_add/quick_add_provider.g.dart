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
    extends $NotifierProvider<QuickAddNotifier, QuickAddDraft> {
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
  Override overrideWithValue(QuickAddDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickAddDraft>(value),
    );
  }
}

String _$quickAddNotifierHash() => r'445fa631ef25cfae22a261dd64a66c5e9a6836b5';

abstract class _$QuickAddNotifier extends $Notifier<QuickAddDraft> {
  QuickAddDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuickAddDraft, QuickAddDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickAddDraft, QuickAddDraft>,
              QuickAddDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
