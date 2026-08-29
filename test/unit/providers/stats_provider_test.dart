import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAccountRepository mockAccountRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late MockLoanEventRepository mockLoanEventRepo;
  late MockCategoryOverrideRepository mockCategoryOverrideRepo;

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockLoanEventRepo = MockLoanEventRepository();
    when(() => mockLoanEventRepo.getAll()).thenReturn([]);
    mockCategoryOverrideRepo = MockCategoryOverrideRepository();

    when(() => mockAccountRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getActive()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getActive()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        revenueRepositoryProvider.overrideWithValue(mockRevenueRepo),
        loanRepositoryProvider.overrideWithValue(mockLoanRepo),
        loanEventRepositoryProvider.overrideWithValue(mockLoanEventRepo),
        categoryOverrideRepositoryProvider.overrideWithValue(
          mockCategoryOverrideRepo,
        ),
      ],
    );
  }

  test(
    'categorySummaries should calculate percentages relative to Total Expenses + Loans',
    () async {
      final foodExpense = ExpenseModel.create(
        name: 'Food expense',
        amount: 600,
        categorySlug: 'alimentation.supermarche',
        accountId: 1,
        startDate: DateTime.now(),
        frequency: 'Mensuel',
      );
      final transportExpense = ExpenseModel.create(
        name: 'Transport expense',
        amount: 200,
        categorySlug: 'transport.essence',
        accountId: 1,
        startDate: DateTime.now(),
        frequency: 'Mensuel',
      );

      when(
        () => mockExpenseRepo.getAll(),
      ).thenReturn([foodExpense, transportExpense]);
      when(
        () => mockExpenseRepo.getActive(),
      ).thenReturn([foodExpense, transportExpense]);
      when(() => mockLoanRepo.getAll()).thenReturn([]);
      when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);
      await container.read(revenueProvider.future);
      await container.read(loanProvider.future);
      await container.read(categoryDisplayResolverProvider.future);
      await container.read(categoryDisplayResolverProvider.future);

      final state = container.read(statsProvider);
      final summaries = state.categorySummaries;

      expect(summaries.length, 2);

      final foodSummary = summaries.firstWhere(
        (s) => s.groupKey == 'alimentation',
      );
      expect(foodSummary.percentage, closeTo(0.75, 0.01));

      final transportSummary = summaries.firstWhere(
        (s) => s.groupKey == 'transport',
      );
      expect(transportSummary.percentage, closeTo(0.25, 0.01));
    },
  );

  test(
    'categorySummaries is empty when totalExpenses is 0 (no division by zero)',
    () async {
      when(() => mockExpenseRepo.getAll()).thenReturn([]);
      when(() => mockLoanRepo.getAll()).thenReturn([]);
      when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);
      await container.read(revenueProvider.future);
      await container.read(loanProvider.future);
      await container.read(categoryDisplayResolverProvider.future);

      final state = container.read(statsProvider);
      expect(state.categorySummaries, isEmpty);
      expect(state.totalExpenses, 0.0);
    },
  );

  test('uncategorised expenses get their own bucket', () async {
    final orphan = ExpenseModel.create(
      name: 'Inconnu',
      amount: 100,
      startDate: DateTime(2020),
      frequency: 'Mensuel',
      accountId: 1,
    );
    final known = ExpenseModel.create(
      name: 'Courses',
      amount: 300,
      categorySlug: 'alimentation.supermarche',
      startDate: DateTime(2020),
      frequency: 'Mensuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([orphan, known]);
    when(() => mockExpenseRepo.getActive()).thenReturn([orphan, known]);

    final container = makeContainer();
    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(categoryDisplayResolverProvider.future);

    final summaries = container.read(statsProvider).categorySummaries;

    expect(summaries, hasLength(2));
    final bucket = summaries.firstWhere(
      (s) => s.groupKey == CategoryDisplayResolver.uncategorizedKey,
    );
    expect(bucket.categoryName, 'Non catégorisé');
    expect(bucket.amount, 100);
    expect(
      summaries.fold<double>(0, (sum, s) => sum + s.percentage),
      closeTo(1.0, 0.001),
    );
  });

  test('categorySummaries is sorted by amount descending', () async {
    final foodExpense = ExpenseModel.create(
      name: 'Food',
      amount: 200,
      categorySlug: 'alimentation.supermarche',
      accountId: 1,
      startDate: DateTime.now(),
      frequency: 'Mensuel',
    );
    final transportExpense = ExpenseModel.create(
      name: 'Transport',
      amount: 600,
      categorySlug: 'transport.essence',
      accountId: 1,
      startDate: DateTime.now(),
      frequency: 'Mensuel',
    );

    when(
      () => mockExpenseRepo.getAll(),
    ).thenReturn([foodExpense, transportExpense]);
    when(
      () => mockExpenseRepo.getActive(),
    ).thenReturn([foodExpense, transportExpense]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(categoryDisplayResolverProvider.future);

    final summaries = container.read(statsProvider).categorySummaries;
    expect(summaries.length, 2);
    expect(summaries.first.groupKey, 'transport');
    expect(summaries.last.groupKey, 'alimentation');
  });

  test('dashboard splits expenses into recurring and oneTime', () async {
    final now = DateTime.now();

    final monthly = ExpenseModel.create(
      name: 'Rent',
      amount: 800,
      categorySlug: 'restauration.cafe',
      accountId: 1,
      startDate: DateTime(now.year, now.month, 5),
      frequency: 'Mensuel',
    );
    final annual = ExpenseModel.create(
      name: 'Insurance',
      amount: 1200,
      categorySlug: 'restauration.cafe',
      accountId: 1,
      startDate: DateTime(now.year, now.month, 10),
      frequency: 'Annuel',
    );
    final oneTime = ExpenseModel.create(
      name: 'Repair',
      amount: 300,
      categorySlug: 'restauration.cafe',
      accountId: 1,
      startDate: DateTime(now.year, now.month, 15),
      frequency: 'Ponctuel',
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([monthly, annual, oneTime]);
    when(
      () => mockExpenseRepo.getActive(),
    ).thenReturn([monthly, annual, oneTime]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(categoryDisplayResolverProvider.future);

    final state = container.read(statsProvider);

    expect(state.recurringExpenses, 2000.0);
    expect(state.oneTimeExpenses, 300.0);
  });

  test('dashboard splits revenues into recurring and oneTime', () async {
    final now = DateTime.now();

    final monthly = RevenueModel.create(
      name: 'Salary',
      amount: 3000,
      accountId: 1,
      startDate: DateTime(now.year, now.month, 1),
      frequency: 'Mensuel',
    );
    final oneTime = RevenueModel.create(
      name: 'Gift',
      amount: 500,
      accountId: 1,
      startDate: DateTime(now.year, now.month, 10),
      frequency: 'Ponctuel',
    );

    when(() => mockRevenueRepo.getAll()).thenReturn([monthly, oneTime]);
    when(() => mockRevenueRepo.getActive()).thenReturn([monthly, oneTime]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(categoryDisplayResolverProvider.future);

    final state = container.read(statsProvider);

    expect(state.recurringRevenues, 3000.0);
    expect(state.oneTimeRevenues, 500.0);
  });

  test(
    'dashboard oneTimeExpenses is 0 when no oneTime expenses in current month',
    () async {
      final now = DateTime.now();
      final otherMonth = (now.month % 12) + 1;

      final oneTime = ExpenseModel.create(
        name: 'Repair',
        amount: 300,
        categorySlug: 'restauration.cafe',
        accountId: 1,
        startDate: DateTime(now.year, otherMonth, 15),
        frequency: 'Ponctuel',
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([oneTime]);
      when(() => mockExpenseRepo.getActive()).thenReturn([oneTime]);
      when(() => mockLoanRepo.getAll()).thenReturn([]);
      when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);
      await container.read(revenueProvider.future);
      await container.read(loanProvider.future);
      await container.read(categoryDisplayResolverProvider.future);

      final state = container.read(statsProvider);

      expect(state.oneTimeExpenses, 0.0);
    },
  );

  test(
    'netCashFlow equals revenues minus expenses minus loan payments',
    () async {
      final now = DateTime.now();

      final revenue = RevenueModel.create(
        name: 'Salary',
        amount: 3000,
        accountId: 1,
        startDate: now,
        frequency: 'Mensuel',
      );
      final expense = ExpenseModel.create(
        name: 'Rent',
        amount: 1000,
        categorySlug: 'restauration.cafe',
        accountId: 1,
        startDate: now,
        frequency: 'Mensuel',
      );

      when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
      when(() => mockRevenueRepo.getActive()).thenReturn([revenue]);
      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);
      when(() => mockLoanRepo.getAll()).thenReturn([]);
      when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);
      await container.read(revenueProvider.future);
      await container.read(loanProvider.future);
      await container.read(categoryDisplayResolverProvider.future);

      final state = container.read(statsProvider);
      expect(state.netCashFlow, closeTo(2000.0, 0.01));
    },
  );
}
