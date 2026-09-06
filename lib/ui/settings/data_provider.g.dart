// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DataNotifier)
final dataProvider = DataNotifierProvider._();

final class DataNotifierProvider
    extends $NotifierProvider<DataNotifier, DataState> {
  DataNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataNotifierHash();

  @$internal
  @override
  DataNotifier create() => DataNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataState>(value),
    );
  }
}

String _$dataNotifierHash() => r'c71dfc933f456163fbad0883d2e4927c1db6d262';

abstract class _$DataNotifier extends $Notifier<DataState> {
  DataState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DataState, DataState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DataState, DataState>,
              DataState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
