import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/expense_model.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockExpenseRepository mockExpenseRepo;
  late MockCategoryRepository mockCategoryRepo;

  setUp(() {
    mockExpenseRepo = MockExpenseRepository();
    mockCategoryRepo = MockCategoryRepository();
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockCategoryRepo.getAll()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
      ],
    );
  }

  test('getTotalExpenses (Annual) should show full amount in matching month', () async {
    final expense = ExpenseModel.create(
      name: 'Annual',
      amount: 1200,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Annuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final total = container.read(expenseProvider.notifier).getTotalExpenses();

    expect(total, 1200.0);
  });

  test('getTotalExpenses (Monthly) should sum directly', () async {
    final expense = ExpenseModel.create(
      name: 'Monthly',
      amount: 100,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final total = container.read(expenseProvider.notifier).getTotalExpenses();

    expect(total, 100.0);
  });

  test('getTotalExpenses should sum monthly and annual in matching month', () async {
    final monthly = ExpenseModel.create(
      name: 'Monthly',
      amount: 500,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
      accountId: 1,
    );
    final annual = ExpenseModel.create(
      name: 'Annual',
      amount: 1200,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Annuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([monthly, annual]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final total = container.read(expenseProvider.notifier).getTotalExpenses();

    expect(total, 1700.0);
  });

  test('getTotalExpenses with empty list returns 0.0', () async {
    when(() => mockExpenseRepo.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    expect(container.read(expenseProvider.notifier).getTotalExpenses(), 0.0);
  });

  test('getTotalExpenses with zero-amount expense returns 0.0', () async {
    final zeroExpense = ExpenseModel.create(
      name: 'Zero',
      amount: 0,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([zeroExpense]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    expect(container.read(expenseProvider.notifier).getTotalExpenses(), 0.0);
  });

  test('getExpensesByCategory ignores expenses with unknown categoryId', () async {
    final expense = ExpenseModel.create(
      name: 'Orphan expense',
      amount: 100,
      categoryId: 999,
      date: DateTime.now(),
      frequency: 'Mensuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
    when(() => mockCategoryRepo.get(999)).thenReturn(null);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final result = container.read(expenseProvider.notifier).getExpensesByCategory();

    expect(result, isEmpty);
  });

  test('getUpcomingExpenses includes monthly expense due later this month', () async {
    final now = DateTime.now();
    final futureDay = now.day + 3;
    if (futureDay > 28) return;

    final upcoming = ExpenseModel.create(
      name: 'Upcoming',
      amount: 200,
      categoryId: 1,
      date: DateTime(now.year, now.month, futureDay),
      frequency: 'Mensuel',
      accountId: 1,
    );
    final past = ExpenseModel.create(
      name: 'Past',
      amount: 100,
      categoryId: 1,
      date: DateTime(now.year, now.month, 1),
      frequency: 'Mensuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([upcoming, past]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final result = container.read(expenseProvider.notifier).getUpcomingExpenses();

    expect(result.any((e) => e.name == 'Upcoming'), isTrue);
  });

  test('getTotalExpenses (Annual) should return 0 in non-matching month', () async {
    final now = DateTime.now();
    final otherMonth = (now.month % 12) + 1;
    final expense = ExpenseModel.create(
      name: 'Annual Other',
      amount: 1200,
      categoryId: 1,
      date: DateTime(now.year, otherMonth, 15),
      frequency: 'Annuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final total = container.read(expenseProvider.notifier).getTotalExpenses();

    expect(total, 0.0);
  });

  test('getTotalExpenses (OneTime) should show amount in matching month', () async {
    final now = DateTime.now();
    final expense = ExpenseModel.create(
      name: 'One-time',
      amount: 500,
      categoryId: 1,
      date: DateTime(now.year, now.month, 10),
      frequency: 'Ponctuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final total = container.read(expenseProvider.notifier).getTotalExpenses();

    expect(total, 500.0);
  });

  test('getTotalExpenses (OneTime) should return 0 in non-matching month', () async {
    final now = DateTime.now();
    final otherMonth = (now.month % 12) + 1;
    final expense = ExpenseModel.create(
      name: 'One-time Other',
      amount: 500,
      categoryId: 1,
      date: DateTime(now.year, otherMonth, 10),
      frequency: 'Ponctuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final total = container.read(expenseProvider.notifier).getTotalExpenses();

    expect(total, 0.0);
  });

  test('getTotalExpenses sums monthly, annual and oneTime in matching month', () async {
    final now = DateTime.now();
    final monthly = ExpenseModel.create(
      name: 'Monthly',
      amount: 500,
      categoryId: 1,
      date: DateTime(now.year, now.month, 5),
      frequency: 'Mensuel',
      accountId: 1,
    );
    final annual = ExpenseModel.create(
      name: 'Annual',
      amount: 1200,
      categoryId: 1,
      date: DateTime(now.year, now.month, 10),
      frequency: 'Annuel',
      accountId: 1,
    );
    final oneTime = ExpenseModel.create(
      name: 'One-time',
      amount: 300,
      categoryId: 1,
      date: DateTime(now.year, now.month, 15),
      frequency: 'Ponctuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([monthly, annual, oneTime]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final total = container.read(expenseProvider.notifier).getTotalExpenses();

    expect(total, 2000.0);
  });

  test('getUpcomingExpenses includes oneTime expense due in the future', () async {
    final now = DateTime.now();
    final futureDay = now.day + 3;
    if (futureDay > 28) return;

    final upcoming = ExpenseModel.create(
      name: 'One-time Upcoming',
      amount: 400,
      categoryId: 1,
      date: DateTime(now.year, now.month, futureDay),
      frequency: 'Ponctuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([upcoming]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final result = container.read(expenseProvider.notifier).getUpcomingExpenses();

    expect(result.any((e) => e.name == 'One-time Upcoming'), isTrue);
  });

  test('getUpcomingExpenses excludes oneTime expense in the past', () async {
    final now = DateTime.now();
    final pastDate = now.subtract(const Duration(days: 5));

    final past = ExpenseModel.create(
      name: 'One-time Past',
      amount: 400,
      categoryId: 1,
      date: pastDate,
      frequency: 'Ponctuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([past]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final result = container.read(expenseProvider.notifier).getUpcomingExpenses();

    expect(result.any((e) => e.name == 'One-time Past'), isFalse);
  });

  test('getUpcomingExpenses includes annual expense due this month', () async {
    final now = DateTime.now();
    final futureDay = now.day + 2;
    if (futureDay > 28) return;

    final annualThisMonth = ExpenseModel.create(
      name: 'Annual This Month',
      amount: 300,
      categoryId: 1,
      date: DateTime(now.year, now.month, futureDay),
      frequency: 'Annuel',
      accountId: 1,
    );
    final annualOtherMonth = ExpenseModel.create(
      name: 'Annual Other Month',
      amount: 300,
      categoryId: 1,
      date: DateTime(now.year, (now.month % 12) + 1, 15),
      frequency: 'Annuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([annualThisMonth, annualOtherMonth]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final result = container.read(expenseProvider.notifier).getUpcomingExpenses();

    expect(result.any((e) => e.name == 'Annual This Month'), isTrue);
    expect(result.any((e) => e.name == 'Annual Other Month'), isFalse);
  });
}
