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

String _$revenueNotifierHash() => r'240ad6540c7dbd80d68ce083a3fbabcaf3dc5f94';

abstract class _$RevenueNotifier extends $AsyncNotifier<List<RevenueModel>> {
  FutureOr<List<RevenueModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
