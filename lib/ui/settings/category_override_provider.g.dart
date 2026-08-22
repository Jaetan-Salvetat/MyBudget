// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_override_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoryOverrideNotifier)
final categoryOverrideProvider = CategoryOverrideNotifierProvider._();

final class CategoryOverrideNotifierProvider
    extends
        $AsyncNotifierProvider<
          CategoryOverrideNotifier,
          Map<String, CategoryOverrideModel>
        > {
  CategoryOverrideNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryOverrideProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryOverrideNotifierHash();

  @$internal
  @override
  CategoryOverrideNotifier create() => CategoryOverrideNotifier();
}

String _$categoryOverrideNotifierHash() =>
    r'5707b94b027d7faff1b4ed545de21f7211ff0000';

abstract class _$CategoryOverrideNotifier
    extends $AsyncNotifier<Map<String, CategoryOverrideModel>> {
  FutureOr<Map<String, CategoryOverrideModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, CategoryOverrideModel>>,
              Map<String, CategoryOverrideModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, CategoryOverrideModel>>,
                Map<String, CategoryOverrideModel>
              >,
              AsyncValue<Map<String, CategoryOverrideModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(categoryDisplayResolver)
final categoryDisplayResolverProvider = CategoryDisplayResolverProvider._();

final class CategoryDisplayResolverProvider
    extends
        $FunctionalProvider<
          AsyncValue<CategoryDisplayResolver>,
          CategoryDisplayResolver,
          FutureOr<CategoryDisplayResolver>
        >
    with
        $FutureModifier<CategoryDisplayResolver>,
        $FutureProvider<CategoryDisplayResolver> {
  CategoryDisplayResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryDisplayResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryDisplayResolverHash();

  @$internal
  @override
  $FutureProviderElement<CategoryDisplayResolver> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CategoryDisplayResolver> create(Ref ref) {
    return categoryDisplayResolver(ref);
  }
}

String _$categoryDisplayResolverHash() =>
    r'b686989a418f10f760e481573d06153cb2bb035c';
