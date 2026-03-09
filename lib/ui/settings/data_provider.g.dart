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

String _$dataNotifierHash() => r'03b5a68b9314d0c6418b21a15624a22165d5c6c8';

abstract class _$DataNotifier extends $Notifier<DataState> {
  DataState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DataState, DataState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DataState, DataState>,
              DataState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
