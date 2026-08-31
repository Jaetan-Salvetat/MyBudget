// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_alert_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuickAddAlertNotifier)
final quickAddAlertProvider = QuickAddAlertNotifierProvider._();

final class QuickAddAlertNotifierProvider
    extends $NotifierProvider<QuickAddAlertNotifier, QuickAddAlert?> {
  QuickAddAlertNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddAlertProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddAlertNotifierHash();

  @$internal
  @override
  QuickAddAlertNotifier create() => QuickAddAlertNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuickAddAlert? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickAddAlert?>(value),
    );
  }
}

String _$quickAddAlertNotifierHash() =>
    r'35595a0d9c4db8cb865d05a59996030aadf921d0';

abstract class _$QuickAddAlertNotifier extends $Notifier<QuickAddAlert?> {
  QuickAddAlert? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuickAddAlert?, QuickAddAlert?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickAddAlert?, QuickAddAlert?>,
              QuickAddAlert?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
