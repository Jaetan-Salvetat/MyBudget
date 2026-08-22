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

String _$quickAddNotifierHash() => r'629cba99424b8e047358aec01e2d88cbf2cdd299';

/// Reads the input as it is typed : the amount lands at every keystroke, the
/// model runs on the pause. Submitting creates the transaction straight away,
/// the snackbar owns the way back.

abstract class _$QuickAddNotifier extends $Notifier<QuickAddDraft> {
  QuickAddDraft build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QuickAddDraft, QuickAddDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickAddDraft, QuickAddDraft>,
              QuickAddDraft,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
