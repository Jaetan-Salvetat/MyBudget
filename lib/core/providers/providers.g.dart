// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(objectBoxService)
final objectBoxServiceProvider = ObjectBoxServiceProvider._();

final class ObjectBoxServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ObjectBoxService>,
          ObjectBoxService,
          FutureOr<ObjectBoxService>
        >
    with $FutureModifier<ObjectBoxService>, $FutureProvider<ObjectBoxService> {
  ObjectBoxServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'objectBoxServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$objectBoxServiceHash();

  @$internal
  @override
  $FutureProviderElement<ObjectBoxService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ObjectBoxService> create(Ref ref) {
    return objectBoxService(ref);
  }
}

String _$objectBoxServiceHash() => r'02c6f5f49e110b24ad5cbc0ccc9331e0dad3f814';

@ProviderFor(categoryTaxonomy)
final categoryTaxonomyProvider = CategoryTaxonomyProvider._();

final class CategoryTaxonomyProvider
    extends
        $FunctionalProvider<
          AsyncValue<CategoryTaxonomyService>,
          CategoryTaxonomyService,
          FutureOr<CategoryTaxonomyService>
        >
    with
        $FutureModifier<CategoryTaxonomyService>,
        $FutureProvider<CategoryTaxonomyService> {
  CategoryTaxonomyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryTaxonomyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryTaxonomyHash();

  @$internal
  @override
  $FutureProviderElement<CategoryTaxonomyService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CategoryTaxonomyService> create(Ref ref) {
    return categoryTaxonomy(ref);
  }
}

String _$categoryTaxonomyHash() => r'e51bd73a55feed4804c327a578c57c120b15b9c5';

@ProviderFor(quickAddClassifier)
final quickAddClassifierProvider = QuickAddClassifierProvider._();

final class QuickAddClassifierProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuickAddClassifierService>,
          QuickAddClassifierService,
          FutureOr<QuickAddClassifierService>
        >
    with
        $FutureModifier<QuickAddClassifierService>,
        $FutureProvider<QuickAddClassifierService> {
  QuickAddClassifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddClassifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddClassifierHash();

  @$internal
  @override
  $FutureProviderElement<QuickAddClassifierService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuickAddClassifierService> create(Ref ref) {
    return quickAddClassifier(ref);
  }
}

String _$quickAddClassifierHash() =>
    r'2236a78741d07fe4d5913ef9c856ad7e53a522a0';

@ProviderFor(accountRepository)
final accountRepositoryProvider = AccountRepositoryProvider._();

final class AccountRepositoryProvider
    extends
        $FunctionalProvider<
          AccountRepository,
          AccountRepository,
          AccountRepository
        >
    with $Provider<AccountRepository> {
  AccountRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountRepository create(Ref ref) {
    return accountRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountRepository>(value),
    );
  }
}

String _$accountRepositoryHash() => r'63b065ec16a192a4ae078c58e726ed28f174b2de';

@ProviderFor(beneficiaryRepository)
final beneficiaryRepositoryProvider = BeneficiaryRepositoryProvider._();

final class BeneficiaryRepositoryProvider
    extends
        $FunctionalProvider<
          BeneficiaryRepository,
          BeneficiaryRepository,
          BeneficiaryRepository
        >
    with $Provider<BeneficiaryRepository> {
  BeneficiaryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'beneficiaryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$beneficiaryRepositoryHash();

  @$internal
  @override
  $ProviderElement<BeneficiaryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BeneficiaryRepository create(Ref ref) {
    return beneficiaryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BeneficiaryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BeneficiaryRepository>(value),
    );
  }
}

String _$beneficiaryRepositoryHash() =>
    r'c7f601c1abdf47a60f7bdf62c2e89ea966b28fe0';

@ProviderFor(categoryMemoryRepository)
final categoryMemoryRepositoryProvider = CategoryMemoryRepositoryProvider._();

final class CategoryMemoryRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryMemoryRepository,
          CategoryMemoryRepository,
          CategoryMemoryRepository
        >
    with $Provider<CategoryMemoryRepository> {
  CategoryMemoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryMemoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryMemoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryMemoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryMemoryRepository create(Ref ref) {
    return categoryMemoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryMemoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryMemoryRepository>(value),
    );
  }
}

String _$categoryMemoryRepositoryHash() =>
    r'22209c84cb8e1ab8f440753b91b2d37aeac93e3a';

@ProviderFor(categoryMemory)
final categoryMemoryProvider = CategoryMemoryProvider._();

final class CategoryMemoryProvider
    extends
        $FunctionalProvider<
          CategoryMemoryService,
          CategoryMemoryService,
          CategoryMemoryService
        >
    with $Provider<CategoryMemoryService> {
  CategoryMemoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryMemoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryMemoryHash();

  @$internal
  @override
  $ProviderElement<CategoryMemoryService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryMemoryService create(Ref ref) {
    return categoryMemory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryMemoryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryMemoryService>(value),
    );
  }
}

String _$categoryMemoryHash() => r'90ec89ba5feadabf4d0267fa3e1446ce11ef2bc5';

@ProviderFor(categoryOverrideRepository)
final categoryOverrideRepositoryProvider =
    CategoryOverrideRepositoryProvider._();

final class CategoryOverrideRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryOverrideRepository,
          CategoryOverrideRepository,
          CategoryOverrideRepository
        >
    with $Provider<CategoryOverrideRepository> {
  CategoryOverrideRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryOverrideRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryOverrideRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryOverrideRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryOverrideRepository create(Ref ref) {
    return categoryOverrideRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryOverrideRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryOverrideRepository>(value),
    );
  }
}

String _$categoryOverrideRepositoryHash() =>
    r'62c0edf99e4840196b211f012fed4e21d481b48d';

@ProviderFor(expenseRepository)
final expenseRepositoryProvider = ExpenseRepositoryProvider._();

final class ExpenseRepositoryProvider
    extends
        $FunctionalProvider<
          ExpenseRepository,
          ExpenseRepository,
          ExpenseRepository
        >
    with $Provider<ExpenseRepository> {
  ExpenseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExpenseRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExpenseRepository create(Ref ref) {
    return expenseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpenseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpenseRepository>(value),
    );
  }
}

String _$expenseRepositoryHash() => r'9cf59d1df834988cced608c6293d6d64c8c0fafb';

@ProviderFor(loanRepository)
final loanRepositoryProvider = LoanRepositoryProvider._();

final class LoanRepositoryProvider
    extends $FunctionalProvider<LoanRepository, LoanRepository, LoanRepository>
    with $Provider<LoanRepository> {
  LoanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanRepositoryHash();

  @$internal
  @override
  $ProviderElement<LoanRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoanRepository create(Ref ref) {
    return loanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanRepository>(value),
    );
  }
}

String _$loanRepositoryHash() => r'8e3e72a88bc102b9368b7fa1ed1db9b60d8f6131';

@ProviderFor(loanEventRepository)
final loanEventRepositoryProvider = LoanEventRepositoryProvider._();

final class LoanEventRepositoryProvider
    extends
        $FunctionalProvider<
          LoanEventRepository,
          LoanEventRepository,
          LoanEventRepository
        >
    with $Provider<LoanEventRepository> {
  LoanEventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanEventRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanEventRepositoryHash();

  @$internal
  @override
  $ProviderElement<LoanEventRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LoanEventRepository create(Ref ref) {
    return loanEventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanEventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanEventRepository>(value),
    );
  }
}

String _$loanEventRepositoryHash() =>
    r'e35d6f58b5b29af2d4fabd163ed7dc5f5c62b80b';

@ProviderFor(loanScheduleService)
final loanScheduleServiceProvider = LoanScheduleServiceProvider._();

final class LoanScheduleServiceProvider
    extends
        $FunctionalProvider<
          LoanScheduleService,
          LoanScheduleService,
          LoanScheduleService
        >
    with $Provider<LoanScheduleService> {
  LoanScheduleServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanScheduleServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanScheduleServiceHash();

  @$internal
  @override
  $ProviderElement<LoanScheduleService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LoanScheduleService create(Ref ref) {
    return loanScheduleService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanScheduleService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanScheduleService>(value),
    );
  }
}

String _$loanScheduleServiceHash() =>
    r'9dccdbb5bb4e0cd0e22def68774ff32d72e7947c';

@ProviderFor(loanService)
final loanServiceProvider = LoanServiceProvider._();

final class LoanServiceProvider
    extends $FunctionalProvider<LoanService, LoanService, LoanService>
    with $Provider<LoanService> {
  LoanServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanServiceHash();

  @$internal
  @override
  $ProviderElement<LoanService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoanService create(Ref ref) {
    return loanService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanService>(value),
    );
  }
}

String _$loanServiceHash() => r'c4fbdd36d10aed844e8fb067bbd1b07ef0d1ed6a';

@ProviderFor(loanPayoffService)
final loanPayoffServiceProvider = LoanPayoffServiceProvider._();

final class LoanPayoffServiceProvider
    extends
        $FunctionalProvider<
          LoanPayoffService,
          LoanPayoffService,
          LoanPayoffService
        >
    with $Provider<LoanPayoffService> {
  LoanPayoffServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanPayoffServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanPayoffServiceHash();

  @$internal
  @override
  $ProviderElement<LoanPayoffService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LoanPayoffService create(Ref ref) {
    return loanPayoffService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanPayoffService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanPayoffService>(value),
    );
  }
}

String _$loanPayoffServiceHash() => r'24d05c02f278ff1822bd3a5eb73eef1133d2040e';

@ProviderFor(revenueRepository)
final revenueRepositoryProvider = RevenueRepositoryProvider._();

final class RevenueRepositoryProvider
    extends
        $FunctionalProvider<
          RevenueRepository,
          RevenueRepository,
          RevenueRepository
        >
    with $Provider<RevenueRepository> {
  RevenueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revenueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revenueRepositoryHash();

  @$internal
  @override
  $ProviderElement<RevenueRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RevenueRepository create(Ref ref) {
    return revenueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RevenueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RevenueRepository>(value),
    );
  }
}

String _$revenueRepositoryHash() => r'ade2b8fcb7478cd0e8a080c90b5414d6adebd54d';

@ProviderFor(transferRepository)
final transferRepositoryProvider = TransferRepositoryProvider._();

final class TransferRepositoryProvider
    extends
        $FunctionalProvider<
          TransferRepository,
          TransferRepository,
          TransferRepository
        >
    with $Provider<TransferRepository> {
  TransferRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransferRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransferRepository create(Ref ref) {
    return transferRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransferRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransferRepository>(value),
    );
  }
}

String _$transferRepositoryHash() =>
    r'bdeb25b9db4fd183ab1ce6eae8518fcb7c2de94b';
