// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'356093f90927017ed56702ae30a8d368b6561fba';

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

String _$statsNotifierHash() => r'7c76779ccbd0ac3868465f45a91269c16ee8654c';

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
