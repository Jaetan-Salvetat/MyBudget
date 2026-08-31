// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_account_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuickAddAccountNotifier)
final quickAddAccountProvider = QuickAddAccountNotifierProvider._();

final class QuickAddAccountNotifierProvider
    extends $NotifierProvider<QuickAddAccountNotifier, int?> {
  QuickAddAccountNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddAccountProvider',
        isAutoDispose: false,
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
    r'e883cade2792dbcea2e0e1acf370b449fcca8c01';

abstract class _$QuickAddAccountNotifier extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
