import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository expenses;
  late MockRevenueRepository revenues;
  late MockCategoryOverrideRepository overrides;

  final april = DateTime(2026, 4);
  final june = DateTime(2026, 6);
  final august = DateTime(2026, 8);

  ExpenseModel rent({DateTime? endDate}) {
    final expense = ExpenseModel.create(
      name: 'Loyer',
      amount: 800,
      startDate: DateTime(2026, 4, 12),
      frequency: Frequency.monthly,
      accountId: 1,
      categorySlug: 'logement.loyer',
      endDate: endDate,
    );
    expense.id = 1;
    return expense;
  }

  setUp(() {
    expenses = MockExpenseRepository();
    revenues = MockRevenueRepository();
    overrides = MockCategoryOverrideRepository();

    when(() => overrides.getAll()).thenReturn({});
    when(() => expenses.getActive()).thenReturn([]);
    when(() => expenses.getClosed()).thenReturn([]);
    when(() => revenues.getActive()).thenReturn([]);
    when(() => revenues.getClosed()).thenReturn([]);
  });

  Future<ProviderContainer> containerOn(DateTime month) async {
    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(expenses),
        revenueRepositoryProvider.overrideWithValue(revenues),
        categoryOverrideRepositoryProvider.overrideWithValue(overrides),
      ],
    );
    addTearDown(container.dispose);
    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    container.read(selectedMonthProvider.notifier).setMonth(month);
    return container;
  }

  group('the month total of a rule still open', () {
    test('counts it from the month it started', () async {
      when(() => expenses.getActive()).thenReturn([rent()]);

      final container = await containerOn(april);

      expect(container.read(monthlyExpensesProvider), 800);
    });

    test('counts it every month after that', () async {
      when(() => expenses.getActive()).thenReturn([rent()]);

      final container = await containerOn(august);

      expect(container.read(monthlyExpensesProvider), 800);
    });

    test('counts nothing on the month before it started', () async {
      when(() => expenses.getActive()).thenReturn([rent()]);

      final container = await containerOn(DateTime(2026, 3));

      expect(container.read(monthlyExpensesProvider), 0);
    });
  });

  group('the month total of a rule closed in August', () {
    setUp(() {
      when(
        () => expenses.getClosed(),
      ).thenReturn([rent(endDate: DateTime(2026, 8, 12))]);
    });

    test('still counts it in June', () async {
      final container = await containerOn(june);

      expect(container.read(monthlyExpensesProvider), 800);
    });

    test('still counts it in August, the month it closed', () async {
      final container = await containerOn(august);

      expect(container.read(monthlyExpensesProvider), 800);
    });

    test('drops it in September', () async {
      final container = await containerOn(DateTime(2026, 9));

      expect(container.read(monthlyExpensesProvider), 0);
    });

    test('breaks it down under its group like any other', () async {
      final container = await containerOn(june);
      await container.read(categoryDisplayResolverProvider.future);

      expect(container.read(expensesByGroupProvider).values.single, 800);
    });
  });

  group('a revenue closed in August', () {
    setUp(() {
      final salary = RevenueModel.create(
        name: 'Ancien salaire',
        amount: 2400,
        startDate: DateTime(2026, 4, 2),
        frequency: Frequency.monthly,
        accountId: 1,
        endDate: DateTime(2026, 8, 2),
      );
      salary.id = 1;
      when(() => revenues.getClosed()).thenReturn([salary]);
    });

    test('still counts in June', () async {
      final container = await containerOn(june);

      expect(container.read(monthlyRevenuesProvider), 2400);
    });

    test('drops in September', () async {
      final container = await containerOn(DateTime(2026, 9));

      expect(container.read(monthlyRevenuesProvider), 0);
    });
  });

  group('the list of a month', () {
    test('holds a rule closed that very month', () async {
      when(
        () => expenses.getClosed(),
      ).thenReturn([rent(endDate: DateTime(2026, 8, 12))]);

      final container = await containerOn(august);

      expect(container.read(monthExpensesProvider).single.name, 'Loyer');
    });

    test('holds nothing on the month before the rule started', () async {
      when(() => expenses.getActive()).thenReturn([rent()]);

      final container = await containerOn(DateTime(2026, 3));

      expect(container.read(monthExpensesProvider), isEmpty);
    });

    test('dates each rule on the day it lands that month', () async {
      when(() => expenses.getActive()).thenReturn([rent()]);

      final container = await containerOn(june);

      expect(
        container.read(monthExpensesProvider).single.startDate,
        DateTime(2026, 6, 12),
      );
    });

    test('brings the 31st back to the last day of February', () async {
      final expense = ExpenseModel.create(
        name: 'Abonnement',
        amount: 12,
        startDate: DateTime(2026, 1, 31),
        frequency: Frequency.monthly,
        accountId: 1,
      );
      expense.id = 3;
      when(() => expenses.getActive()).thenReturn([expense]);

      final container = await containerOn(DateTime(2026, 2));

      expect(
        container.read(monthExpensesProvider).single.startDate,
        DateTime(2026, 2, 28),
      );
    });

    test('adds up to the total announced for that month', () async {
      when(() => expenses.getActive()).thenReturn([rent()]);
      when(
        () => expenses.getClosed(),
      ).thenReturn([rent(endDate: DateTime(2026, 8, 12))..id = 2]);

      final container = await containerOn(june);
      final listed = container
          .read(monthExpensesProvider)
          .fold<double>(0, (sum, expense) => sum + expense.amount);

      expect(listed, container.read(monthlyExpensesProvider));
    });

    test('keeps revenues on the same rule', () async {
      final salary = RevenueModel.create(
        name: 'Ancien salaire',
        amount: 2400,
        startDate: DateTime(2026, 4, 2),
        frequency: Frequency.monthly,
        accountId: 1,
        endDate: DateTime(2026, 8, 2),
      );
      salary.id = 1;
      when(() => revenues.getClosed()).thenReturn([salary]);

      final container = await containerOn(june);

      expect(
        container.read(monthRevenuesProvider).single.startDate,
        DateTime(2026, 6, 2),
      );
    });
  });

  group('an edit, which closes one rule and opens another', () {
    test('counts the month once, not twice', () async {
      when(
        () => expenses.getClosed(),
      ).thenReturn([rent(endDate: DateTime(2026, 7, 12))]);

      final raised = ExpenseModel.create(
        name: 'Loyer',
        amount: 850,
        startDate: DateTime(2026, 8, 12),
        frequency: Frequency.monthly,
        accountId: 1,
        categorySlug: 'logement.loyer',
        parentId: 1,
      );
      raised.id = 2;
      when(() => expenses.getActive()).thenReturn([raised]);

      final container = await containerOn(august);

      expect(container.read(monthlyExpensesProvider), 850);
    });
  });
}
