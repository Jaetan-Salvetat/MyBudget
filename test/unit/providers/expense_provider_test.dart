import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/models/expense_model.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

void main() {
  late MockExpenseRepository mockExpenseRepo;

  setUpAll(() {
    registerFallbackValue(FakeExpenseModel());
  });

  setUp(() {
    mockExpenseRepo = MockExpenseRepository();
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getActive()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(mockExpenseRepo)],
    );
  }

  test(
    'getTotalExpenses (Annual) should show full amount in matching month',
    () async {
      final expense = ExpenseModel.create(
        name: 'Annual',
        amount: 1200,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: 'Annuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container.read(expenseProvider.notifier).getTotalExpenses();

      expect(total, 1200.0);
    },
  );

  test('getTotalExpenses (Monthly) should sum directly', () async {
    final expense = ExpenseModel.create(
      name: 'Monthly',
      amount: 100,
      categorySlug: 'restauration.cafe',
      startDate: DateTime.now(),
      frequency: 'Mensuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
    when(() => mockExpenseRepo.getActive()).thenReturn([expense]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final total = container.read(expenseProvider.notifier).getTotalExpenses();

    expect(total, 100.0);
  });

  test(
    'getTotalExpenses should sum monthly and annual in matching month',
    () async {
      final monthly = ExpenseModel.create(
        name: 'Monthly',
        amount: 500,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: 'Mensuel',
        accountId: 1,
      );
      final annual = ExpenseModel.create(
        name: 'Annual',
        amount: 1200,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: 'Annuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([monthly, annual]);
      when(() => mockExpenseRepo.getActive()).thenReturn([monthly, annual]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container.read(expenseProvider.notifier).getTotalExpenses();

      expect(total, 1700.0);
    },
  );

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
      categorySlug: 'restauration.cafe',
      startDate: DateTime.now(),
      frequency: 'Mensuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([zeroExpense]);
    when(() => mockExpenseRepo.getActive()).thenReturn([zeroExpense]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    expect(container.read(expenseProvider.notifier).getTotalExpenses(), 0.0);
  });

  test(
    'getUpcomingExpenses includes monthly expense due later this month',
    () async {
      final now = DateTime.now();
      final futureDay = now.day + 3;
      if (futureDay > 28) return;

      final upcoming = ExpenseModel.create(
        name: 'Upcoming',
        amount: 200,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, now.month, futureDay),
        frequency: 'Mensuel',
        accountId: 1,
      );
      final past = ExpenseModel.create(
        name: 'Past',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, now.month, 1),
        frequency: 'Mensuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([upcoming, past]);
      when(() => mockExpenseRepo.getActive()).thenReturn([upcoming, past]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final result = container
          .read(expenseProvider.notifier)
          .getUpcomingExpenses();

      expect(result.any((e) => e.name == 'Upcoming'), isTrue);
    },
  );

  test(
    'getTotalExpenses (Annual) should return 0 in non-matching month',
    () async {
      final now = DateTime.now();
      final otherMonth = (now.month % 12) + 1;
      final expense = ExpenseModel.create(
        name: 'Annual Other',
        amount: 1200,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, otherMonth, 15),
        frequency: 'Annuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container.read(expenseProvider.notifier).getTotalExpenses();

      expect(total, 0.0);
    },
  );

  test(
    'getTotalExpenses (OneTime) should show amount in matching month',
    () async {
      final now = DateTime.now();
      final expense = ExpenseModel.create(
        name: 'One-time',
        amount: 500,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, now.month, 10),
        frequency: 'Ponctuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container.read(expenseProvider.notifier).getTotalExpenses();

      expect(total, 500.0);
    },
  );

  test(
    'getTotalExpenses (OneTime) should return 0 in non-matching month',
    () async {
      final now = DateTime.now();
      final otherMonth = (now.month % 12) + 1;
      final expense = ExpenseModel.create(
        name: 'One-time Other',
        amount: 500,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, otherMonth, 10),
        frequency: 'Ponctuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container.read(expenseProvider.notifier).getTotalExpenses();

      expect(total, 0.0);
    },
  );

  test(
    'getTotalExpenses sums monthly, annual and oneTime in matching month',
    () async {
      final now = DateTime.now();
      final monthly = ExpenseModel.create(
        name: 'Monthly',
        amount: 500,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, now.month, 5),
        frequency: 'Mensuel',
        accountId: 1,
      );
      final annual = ExpenseModel.create(
        name: 'Annual',
        amount: 1200,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, now.month, 10),
        frequency: 'Annuel',
        accountId: 1,
      );
      final oneTime = ExpenseModel.create(
        name: 'One-time',
        amount: 300,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, now.month, 15),
        frequency: 'Ponctuel',
        accountId: 1,
      );

      when(
        () => mockExpenseRepo.getAll(),
      ).thenReturn([monthly, annual, oneTime]);
      when(
        () => mockExpenseRepo.getActive(),
      ).thenReturn([monthly, annual, oneTime]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container.read(expenseProvider.notifier).getTotalExpenses();

      expect(total, 2000.0);
    },
  );

  test('getUpcomingExpenses excludes oneTime expenses', () async {
    final now = DateTime.now();
    final futureDay = now.day + 3;
    if (futureDay > 28) return;

    final oneTime = ExpenseModel.create(
      name: 'One-time Upcoming',
      amount: 400,
      categorySlug: 'restauration.cafe',
      startDate: DateTime(now.year, now.month, futureDay),
      frequency: 'Ponctuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([oneTime]);
    when(() => mockExpenseRepo.getActive()).thenReturn([oneTime]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final result = container
        .read(expenseProvider.notifier)
        .getUpcomingExpenses();

    expect(result, isEmpty);
  });

  test('getUpcomingExpenses includes annual expense due this month', () async {
    final now = DateTime.now();
    final futureDay = now.day + 2;
    if (futureDay > 28) return;

    final annualThisMonth = ExpenseModel.create(
      name: 'Annual This Month',
      amount: 300,
      categorySlug: 'restauration.cafe',
      startDate: DateTime(now.year, now.month, futureDay),
      frequency: 'Annuel',
      accountId: 1,
    );
    final annualOtherMonth = ExpenseModel.create(
      name: 'Annual Other Month',
      amount: 300,
      categorySlug: 'restauration.cafe',
      startDate: DateTime(now.year, (now.month % 12) + 1, 15),
      frequency: 'Annuel',
      accountId: 1,
    );

    when(
      () => mockExpenseRepo.getAll(),
    ).thenReturn([annualThisMonth, annualOtherMonth]);
    when(
      () => mockExpenseRepo.getActive(),
    ).thenReturn([annualThisMonth, annualOtherMonth]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final result = container
        .read(expenseProvider.notifier)
        .getUpcomingExpenses();

    expect(result.any((e) => e.name == 'Annual This Month'), isTrue);
    expect(result.any((e) => e.name == 'Annual Other Month'), isFalse);
  });

  test(
    'getTotalExpenses counts annual expense from different year if month matches',
    () async {
      final now = DateTime.now();
      final expense = ExpenseModel.create(
        name: 'Annual Old Year',
        amount: 600,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2020, now.month, 10),
        frequency: 'Annuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container.read(expenseProvider.notifier).getTotalExpenses();

      expect(total, 600.0);
    },
  );

  test(
    'getTotalExpenses ignores oneTime from different year same month',
    () async {
      final now = DateTime.now();
      final expense = ExpenseModel.create(
        name: 'OneTime Last Year',
        amount: 500,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year - 1, now.month, 10),
        frequency: 'Ponctuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container.read(expenseProvider.notifier).getTotalExpenses();

      expect(total, 0.0);
    },
  );

  test(
    'getAnnualExpenses calculates monthly*12 + annual + oneTime of year',
    () async {
      final now = DateTime.now();
      final monthly = ExpenseModel.create(
        name: 'Monthly',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, now.month, 5),
        frequency: 'Mensuel',
        accountId: 1,
      );
      final annual = ExpenseModel.create(
        name: 'Annual',
        amount: 600,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, 3, 10),
        frequency: 'Annuel',
        accountId: 1,
      );
      final oneTimeThisYear = ExpenseModel.create(
        name: 'OneTime This Year',
        amount: 200,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year, 6, 15),
        frequency: 'Ponctuel',
        accountId: 1,
      );
      final oneTimeOtherYear = ExpenseModel.create(
        name: 'OneTime Other Year',
        amount: 300,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(now.year - 1, 6, 15),
        frequency: 'Ponctuel',
        accountId: 1,
      );

      when(
        () => mockExpenseRepo.getAll(),
      ).thenReturn([monthly, annual, oneTimeThisYear, oneTimeOtherYear]);
      when(
        () => mockExpenseRepo.getActive(),
      ).thenReturn([monthly, annual, oneTimeThisYear, oneTimeOtherYear]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final total = container
          .read(expenseProvider.notifier)
          .getAnnualExpenses();

      expect(total, 2000.0);
    },
  );

  test('getAnnualExpenses with empty list returns 0.0', () async {
    when(() => mockExpenseRepo.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    expect(container.read(expenseProvider.notifier).getAnnualExpenses(), 0.0);
  });

  test('deleteExpense soft deletes recurring expense', () async {
    final expense = ExpenseModel.create(
      name: 'Loyer',
      amount: 800,
      categorySlug: 'restauration.cafe',
      startDate: DateTime(2024, 6, 15),
      frequency: 'Mensuel',
      accountId: 1,
    )..id = 1;

    when(() => mockExpenseRepo.get(1)).thenReturn(expense);
    when(() => mockExpenseRepo.update(any())).thenReturn(1);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(expenseProvider.notifier).deleteExpense(1);

    verify(() => mockExpenseRepo.update(any())).called(1);
    verifyNever(() => mockExpenseRepo.delete(any()));
  });

  test('deleteExpense hard deletes oneTime expense', () async {
    final expense = ExpenseModel.create(
      name: 'Achat unique',
      amount: 200,
      categorySlug: 'restauration.cafe',
      startDate: DateTime(2024, 6, 15),
      frequency: 'Ponctuel',
      accountId: 1,
    )..id = 2;

    when(() => mockExpenseRepo.get(2)).thenReturn(expense);
    when(() => mockExpenseRepo.delete(2)).thenReturn(true);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(expenseProvider.notifier).deleteExpense(2);

    verify(() => mockExpenseRepo.delete(2)).called(1);
    verifyNever(() => mockExpenseRepo.update(any()));
  });

  test('updateExpense with name-only change propagates to chain', () async {
    final existing = ExpenseModel.create(
      name: 'Ancien nom',
      amount: 100,
      categorySlug: 'restauration.cafe',
      startDate: DateTime(2024, 6, 15),
      frequency: 'Mensuel',
      accountId: 1,
    )..id = 1;

    final chainEntry = ExpenseModel.create(
      name: 'Ancien nom',
      amount: 100,
      categorySlug: 'restauration.cafe',
      startDate: DateTime(2024, 8, 15),
      frequency: 'Mensuel',
      accountId: 1,
      parentId: 1,
    )..id = 2;

    when(() => mockExpenseRepo.get(1)).thenReturn(existing);
    when(() => mockExpenseRepo.getChain(1)).thenReturn([existing, chainEntry]);
    when(() => mockExpenseRepo.update(any())).thenReturn(1);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final updated = existing.copyWith(name: 'Nouveau nom');
    await container.read(expenseProvider.notifier).updateExpense(updated);

    verify(() => mockExpenseRepo.getChain(1)).called(1);
    verify(() => mockExpenseRepo.update(any())).called(2);
  });

  test(
    'updateExpense with structural change on recurring closes old and creates new',
    () async {
      final existing = ExpenseModel.create(
        name: 'Loyer',
        amount: 500,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 6, 15),
        frequency: 'Mensuel',
        accountId: 1,
      )..id = 1;

      when(() => mockExpenseRepo.get(1)).thenReturn(existing);
      when(() => mockExpenseRepo.update(any())).thenReturn(1);
      when(() => mockExpenseRepo.add(any())).thenReturn(2);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final updated = existing.copyWith(amount: 600);
      await container.read(expenseProvider.notifier).updateExpense(updated);

      verify(() => mockExpenseRepo.update(any())).called(1);
      verify(() => mockExpenseRepo.add(any())).called(1);
    },
  );

  test(
    'updateExpense with structural change on oneTime does simple update',
    () async {
      final existing = ExpenseModel.create(
        name: 'Achat',
        amount: 300,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 6, 15),
        frequency: 'Ponctuel',
        accountId: 1,
      )..id = 1;

      when(() => mockExpenseRepo.get(1)).thenReturn(existing);
      when(() => mockExpenseRepo.update(any())).thenReturn(1);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      final updated = existing.copyWith(amount: 400);
      await container.read(expenseProvider.notifier).updateExpense(updated);

      verify(() => mockExpenseRepo.update(any())).called(1);
      verifyNever(() => mockExpenseRepo.add(any()));
    },
  );

  test('getClosedExpenses returns closed entries', () async {
    final closed = ExpenseModel.create(
      name: 'Ancien',
      amount: 100,
      categorySlug: 'restauration.cafe',
      startDate: DateTime(2024, 1, 15),
      frequency: 'Mensuel',
      accountId: 1,
      endDate: DateTime(2024, 6, 15),
    )..id = 1;

    when(() => mockExpenseRepo.getClosed()).thenReturn([closed]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);

    final result = container.read(expenseProvider.notifier).getClosedExpenses();

    expect(result.length, 1);
    expect(result.first.endDate, isNotNull);
  });
}
