// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequent_categories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(frequentCategories)
final frequentCategoriesProvider = FrequentCategoriesFamily._();

final class FrequentCategoriesProvider
    extends
        $FunctionalProvider<
          List<CategoryDisplay>,
          List<CategoryDisplay>,
          List<CategoryDisplay>
        >
    with $Provider<List<CategoryDisplay>> {
  FrequentCategoriesProvider._({
    required FrequentCategoriesFamily super.from,
    required TransactionType? super.argument,
  }) : super(
         retry: null,
         name: r'frequentCategoriesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$frequentCategoriesHash();

  @override
  String toString() {
    return r'frequentCategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<CategoryDisplay>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CategoryDisplay> create(Ref ref) {
    final argument = this.argument as TransactionType?;
    return frequentCategories(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CategoryDisplay> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CategoryDisplay>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FrequentCategoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$frequentCategoriesHash() =>
    r'0770cbdab37cf2b418ef18392c09cae30706b1cf';

final class FrequentCategoriesFamily extends $Family
    with $FunctionalFamilyOverride<List<CategoryDisplay>, TransactionType?> {
  FrequentCategoriesFamily._()
    : super(
        retry: null,
        name: r'frequentCategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  FrequentCategoriesProvider call(TransactionType? type) =>
      FrequentCategoriesProvider._(argument: type, from: this);

  @override
  String toString() => r'frequentCategoriesProvider';
}
