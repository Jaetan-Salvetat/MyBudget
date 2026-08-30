// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads the input as it is typed : the amount lands at every keystroke, the
/// model runs on the pause. Submitting creates the transaction straight away,
/// the snackbar owns the way back.

@ProviderFor(QuickAddNotifier)
final quickAddProvider = QuickAddNotifierProvider._();

/// Reads the input as it is typed : the amount lands at every keystroke, the
/// model runs on the pause. Submitting creates the transaction straight away,
/// the snackbar owns the way back.
final class QuickAddNotifierProvider
    extends $NotifierProvider<QuickAddNotifier, QuickAddDraft> {
  /// Reads the input as it is typed : the amount lands at every keystroke, the
  /// model runs on the pause. Submitting creates the transaction straight away,
  /// the snackbar owns the way back.
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

String _$quickAddNotifierHash() => r'a96f92f2582d1e9790a96ce6f4d08c52f23273a8';

/// Reads the input as it is typed : the amount lands at every keystroke, the
/// model runs on the pause. Submitting creates the transaction straight away,
/// the snackbar owns the way back.

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
