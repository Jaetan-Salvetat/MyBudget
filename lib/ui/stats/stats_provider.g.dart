// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(statsActiveMonths)
final statsActiveMonthsProvider = StatsActiveMonthsProvider._();

final class StatsActiveMonthsProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  StatsActiveMonthsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsActiveMonthsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsActiveMonthsHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return statsActiveMonths(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$statsActiveMonthsHash() => r'15bbc540b35824f04b9632cb6a7e129067c83c1c';

@ProviderFor(StatsRangeNotifier)
final statsRangeProvider = StatsRangeNotifierProvider._();

final class StatsRangeNotifierProvider
    extends $NotifierProvider<StatsRangeNotifier, StatsRange> {
  StatsRangeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsRangeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsRangeNotifierHash();

  @$internal
  @override
  StatsRangeNotifier create() => StatsRangeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsRange>(value),
    );
  }
}

String _$statsRangeNotifierHash() =>
    r'66e177c5ad001b2ed56c9fc81641a60828749189';

abstract class _$StatsRangeNotifier extends $Notifier<StatsRange> {
  StatsRange build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StatsRange, StatsRange>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StatsRange, StatsRange>,
              StatsRange,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(StatsNotifier)
final statsProvider = StatsNotifierProvider._();

final class StatsNotifierProvider
    extends $NotifierProvider<StatsNotifier, StatsState> {
  StatsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsNotifierHash();

  @$internal
  @override
  StatsNotifier create() => StatsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsState>(value),
    );
  }
}

String _$statsNotifierHash() => r'841d868fb155812c7a35fa2895cb4571c93e8c4a';

abstract class _$StatsNotifier extends $Notifier<StatsState> {
  StatsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StatsState, StatsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StatsState, StatsState>,
              StatsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
