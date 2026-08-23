// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeWidgetNotifier)
final homeWidgetProvider = HomeWidgetNotifierProvider._();

final class HomeWidgetNotifierProvider
    extends $NotifierProvider<HomeWidgetNotifier, DateTime> {
  HomeWidgetNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetNotifierHash();

  @$internal
  @override
  HomeWidgetNotifier create() => HomeWidgetNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$homeWidgetNotifierHash() =>
    r'7087340a9f52210686172e4081d55ecb467f53fd';

abstract class _$HomeWidgetNotifier extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
