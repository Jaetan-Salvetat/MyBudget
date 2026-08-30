// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$statsNotifierHash() => r'4aa26feef1d2e727c9188b33df204216a1d3b12e';

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
