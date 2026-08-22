import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/common/providers/frequent_categories_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockCategoryOverrideRepository overrideRepository;

  setUp(() {
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    overrideRepository = MockCategoryOverrideRepository();

    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => overrideRepository.getAll()).thenReturn({});
  });

  ExpenseModel expense(String? slug, {int day = 1}) => ExpenseModel.create(
    name: 'x',
    amount: 10,
    categorySlug: slug,
    accountId: 1,
    startDate: DateTime(2026, 1, day),
    frequency: 'Mensuel',
  );

  RevenueModel revenue(String? slug) => RevenueModel.create(
    name: 'x',
    amount: 10,
    categorySlug: slug,
    accountId: 1,
    startDate: DateTime(2026, 1, 1),
    frequency: 'Mensuel',
  );

  Future<List<String>> slugsFor(TransactionType type) async {
    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        revenueRepositoryProvider.overrideWithValue(revenueRepository),
        categoryOverrideRepositoryProvider.overrideWithValue(
          overrideRepository,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(categoryDisplayResolverProvider.future);

    return container
        .read(frequentCategoriesProvider(type))
        .map((category) => category.slug)
        .toList();
  }

  test('ranks by number of entries, most used first', () async {
    when(() => expenseRepository.getActive()).thenReturn([
      expense('transport.essence'),
      expense('restauration.cafe'),
      expense('restauration.cafe'),
      expense('restauration.cafe'),
      expense('alimentation.marche'),
      expense('alimentation.marche'),
    ]);

    expect(await slugsFor(TransactionType.expense), [
      'restauration.cafe',
      'alimentation.marche',
      'transport.essence',
    ]);
  });

  test('breaks ties with the most recent start date', () async {
    when(() => expenseRepository.getActive()).thenReturn([
      expense('transport.essence', day: 20),
      expense('restauration.cafe', day: 5),
    ]);

    expect(await slugsFor(TransactionType.expense), [
      'transport.essence',
      'restauration.cafe',
    ]);
  });

  test('ignores entries without a category or with an unknown slug', () async {
    when(() => expenseRepository.getActive()).thenReturn([
      expense(null),
      expense('inconnu.autre'),
      expense('transport.essence'),
    ]);

    expect(await slugsFor(TransactionType.expense), ['transport.essence']);
  });

  test('caps the result at maxFrequentCategories', () async {
    when(() => expenseRepository.getActive()).thenReturn([
      for (final leaf in [
        'transport.essence',
        'transport.parking',
        'transport.peage',
        'restauration.cafe',
        'restauration.bar',
        'alimentation.marche',
      ])
        expense(leaf),
    ]);

    expect(
      (await slugsFor(TransactionType.expense)).length,
      maxFrequentCategories,
    );
  });

  test('reads revenues for the income type', () async {
    when(
      () => expenseRepository.getActive(),
    ).thenReturn([expense('transport.essence')]);
    when(
      () => revenueRepository.getActive(),
    ).thenReturn([revenue('salaire.prime')]);

    expect(await slugsFor(TransactionType.income), ['salaire.prime']);
  });

  test('resolves through the user customisation', () async {
    when(() => overrideRepository.getAll()).thenReturn({
      'transport.essence': CategoryOverrideModel.create(
        slug: 'transport.essence',
        name: 'Carburant',
      ),
    });
    when(
      () => expenseRepository.getActive(),
    ).thenReturn([expense('transport.essence')]);

    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        revenueRepositoryProvider.overrideWithValue(revenueRepository),
        categoryOverrideRepositoryProvider.overrideWithValue(
          overrideRepository,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(categoryDisplayResolverProvider.future);

    expect(
      container
          .read(frequentCategoriesProvider(TransactionType.expense))
          .single
          .label,
      'Carburant',
    );
  });
}
