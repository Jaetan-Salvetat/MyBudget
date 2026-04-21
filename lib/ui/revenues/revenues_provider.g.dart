// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenues_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RevenueNotifier)
final revenueProvider = RevenueNotifierProvider._();

final class RevenueNotifierProvider
    extends $AsyncNotifierProvider<RevenueNotifier, List<RevenueModel>> {
  RevenueNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revenueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revenueNotifierHash();

  @$internal
  @override
  RevenueNotifier create() => RevenueNotifier();
}

String _$revenueNotifierHash() => r'aa580c68cb0c745b57898549c1791622ba29ee6f';

abstract class _$RevenueNotifier extends $AsyncNotifier<List<RevenueModel>> {
  FutureOr<List<RevenueModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<RevenueModel>>, List<RevenueModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<RevenueModel>>, List<RevenueModel>>,
              AsyncValue<List<RevenueModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
