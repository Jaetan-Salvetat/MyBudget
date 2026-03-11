import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/dashboard/dashboard_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/category_model.dart';
class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockAccountRepository mockAccountRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late MockCategoryRepository mockCategoryRepo;

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockCategoryRepo = MockCategoryRepository();

    when(() => mockAccountRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockCategoryRepo.getAll()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        revenueRepositoryProvider.overrideWithValue(mockRevenueRepo),
        loanRepositoryProvider.overrideWithValue(mockLoanRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
      ],
    );
  }

  test(
    'categorySummaries should calculate percentages relative to Total Expenses + Loans',
    () async {
      final catFood = CategoryModel.create(
        name: 'Food',
        icon: 'fastfood',
        color: 0xFF0000,
      )..id = 1;
      final catTransport = CategoryModel.create(
        name: 'Transport',
        icon: 'car',
        color: 0xFF0000,
      )..id = 2;

      final foodExpense = ExpenseModel.create(
        name: 'Food expense',
        amount: 600,
        categoryId: catFood.id,
        accountId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
      );
      final transportExpense = ExpenseModel.create(
        name: 'Transport expense',
        amount: 200,
        categoryId: catTransport.id,
        accountId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([foodExpense, transportExpense]);
      when(() => mockCategoryRepo.get(catFood.id)).thenReturn(catFood);
      when(() => mockCategoryRepo.get(catTransport.id)).thenReturn(catTransport);
      when(() => mockLoanRepo.getAll()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);
      await container.read(revenueProvider.future);
      await container.read(loanProvider.future);

      final state = container.read(dashboardProvider);
      final summaries = state.categorySummaries;

      expect(summaries.length, 2);

      final foodSummary = summaries.firstWhere((s) => s.categoryName == 'Food');
      expect(foodSummary.percentage, closeTo(0.75, 0.01));

      final transportSummary = summaries.firstWhere(
        (s) => s.categoryName == 'Transport',
      );
      expect(transportSummary.percentage, closeTo(0.25, 0.01));
    },
  );

  test('categorySummaries is empty when totalExpenses is 0 (no division by zero)', () async {
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);

    final state = container.read(dashboardProvider);
    expect(state.categorySummaries, isEmpty);
    expect(state.totalExpenses, 0.0);
  });

  test('categorySummaries is sorted by amount descending', () async {
    final catFood = CategoryModel.create(name: 'Food', icon: 'fastfood', color: 0xFF0000)..id = 1;
    final catTransport = CategoryModel.create(name: 'Transport', icon: 'car', color: 0xFF0000)..id = 2;

    final foodExpense = ExpenseModel.create(
      name: 'Food',
      amount: 200,
      categoryId: catFood.id,
      accountId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
    );
    final transportExpense = ExpenseModel.create(
      name: 'Transport',
      amount: 600,
      categoryId: catTransport.id,
      accountId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([foodExpense, transportExpense]);
    when(() => mockCategoryRepo.get(catFood.id)).thenReturn(catFood);
    when(() => mockCategoryRepo.get(catTransport.id)).thenReturn(catTransport);
    when(() => mockLoanRepo.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);

    final summaries = container.read(dashboardProvider).categorySummaries;
    expect(summaries.length, 2);
    expect(summaries.first.categoryName, 'Transport');
    expect(summaries.last.categoryName, 'Food');
  });

  test('netCashFlow equals revenues minus expenses minus loan payments', () async {
    final now = DateTime.now();

    final revenue = RevenueModel.create(
      name: 'Salary',
      amount: 3000,
      accountId: 1,
      date: now,

    );
    final expense = ExpenseModel.create(
      name: 'Rent',
      amount: 1000,
      categoryId: 1,
      accountId: 1,
      date: now,
      frequency: 'Mensuel',
    );

    when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockCategoryRepo.get(1)).thenReturn(null);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);

    final state = container.read(dashboardProvider);
    expect(state.netCashFlow, closeTo(2000.0, 0.01));
  });

}
