// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_focus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lets a caller far from the input ask for it — the nav pill action, from
/// another tab. Only the change matters, the counter is the signal.

@ProviderFor(QuickAddFocusRequest)
final quickAddFocusRequestProvider = QuickAddFocusRequestProvider._();

/// Lets a caller far from the input ask for it — the nav pill action, from
/// another tab. Only the change matters, the counter is the signal.
final class QuickAddFocusRequestProvider
    extends $NotifierProvider<QuickAddFocusRequest, int> {
  /// Lets a caller far from the input ask for it — the nav pill action, from
  /// another tab. Only the change matters, the counter is the signal.
  QuickAddFocusRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddFocusRequestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddFocusRequestHash();

  @$internal
  @override
  QuickAddFocusRequest create() => QuickAddFocusRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$quickAddFocusRequestHash() =>
    r'12796afe02484579bfa47ff74ca0e0de213cf917';

/// Lets a caller far from the input ask for it — the nav pill action, from
/// another tab. Only the change matters, the counter is the signal.

abstract class _$QuickAddFocusRequest extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
