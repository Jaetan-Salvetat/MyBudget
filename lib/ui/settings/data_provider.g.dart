// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DataNotifier)
const dataProvider = DataNotifierProvider._();

final class DataNotifierProvider
    extends $NotifierProvider<DataNotifier, DataState> {
  const DataNotifierProvider._()
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

String _$dataNotifierHash() => r'f071ac25cc5e00b1a98711bd5d7fc2ea63abc63a';

abstract class _$DataNotifier extends $Notifier<DataState> {
  DataState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DataState, DataState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DataState, DataState>,
              DataState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
