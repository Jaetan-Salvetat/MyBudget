// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_account_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The account a quick-added transaction lands on. Defaults to the first one
/// and holds the user's pick as long as that account still exists.

@ProviderFor(QuickAddAccountNotifier)
final quickAddAccountProvider = QuickAddAccountNotifierProvider._();

/// The account a quick-added transaction lands on. Defaults to the first one
/// and holds the user's pick as long as that account still exists.
final class QuickAddAccountNotifierProvider
    extends $NotifierProvider<QuickAddAccountNotifier, int?> {
  /// The account a quick-added transaction lands on. Defaults to the first one
  /// and holds the user's pick as long as that account still exists.
  QuickAddAccountNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddAccountNotifierHash();

  @$internal
  @override
  QuickAddAccountNotifier create() => QuickAddAccountNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$quickAddAccountNotifierHash() =>
    r'b7b6f269692a2d5a9036f321f6df3e2999459c09';

/// The account a quick-added transaction lands on. Defaults to the first one
/// and holds the user's pick as long as that account still exists.

abstract class _$QuickAddAccountNotifier extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
