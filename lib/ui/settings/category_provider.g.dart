// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoryNotifier)
final categoryProvider = CategoryNotifierProvider._();

final class CategoryNotifierProvider
    extends $AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>> {
  CategoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryNotifierHash();

  @$internal
  @override
  CategoryNotifier create() => CategoryNotifier();
}

String _$categoryNotifierHash() => r'70b83c81985846e935e6cfe16f9d0ba6cdc7fa4e';

abstract class _$CategoryNotifier extends $AsyncNotifier<List<CategoryModel>> {
  FutureOr<List<CategoryModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CategoryModel>>, List<CategoryModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CategoryModel>>, List<CategoryModel>>,
              AsyncValue<List<CategoryModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
