import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';

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
    'getAccountBalance should calculate monthly remaining budget correctly',
    () async {
      const int accountId = 1;

      final revenue = RevenueModel.create(
        name: 'Salary',
        amount: 2000,
        accountId: accountId,
        date: DateTime.now(),

      );
      when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);

      final expense = ExpenseModel.create(
        name: 'Groceries',
        amount: 500,
        accountId: accountId,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
      );
      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);

      final loanModel = LoanModel.create(
        name: 'Car Loan',
        amount: 5000,
        duration: 12,
        interestRate: 5,
        accountId: accountId,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        dayOfMonth: 1,
        lenderName: 'Bank',
      );
      when(() => mockLoanRepo.getAll()).thenReturn([loanModel]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);
      await container.read(revenueProvider.future);
      await container.read(loanProvider.future);
      await container.read(accountProvider.future);

      final balance = container.read(accountProvider.notifier).getAccountBalance(accountId);

      expect(balance, closeTo(1071.96, 0.01));
    },
  );

  test('getAccountBalance returns 0 when no revenues/expenses/loans', () async {
    const int accountId = 1;
    when(() => mockAccountRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(accountProvider.future);

    expect(container.read(accountProvider.notifier).getAccountBalance(accountId), 0.0);
  });

  test('getAccountBalance returns negative value when expenses exceed revenues', () async {
    const int accountId = 1;

    final revenue = RevenueModel.create(
      name: 'Small income',
      amount: 100,
      accountId: accountId,
      date: DateTime.now(),

    );
    final expense = ExpenseModel.create(
      name: 'Big expense',
      amount: 800,
      accountId: accountId,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
    );

    when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(accountProvider.future);

    final balance = container.read(accountProvider.notifier).getAccountBalance(accountId);
    expect(balance, -700.0);
  });

  test('getTotalBalance returns 0.0 with no accounts', () async {
    when(() => mockAccountRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(accountProvider.future);

    expect(container.read(accountProvider.notifier).getTotalBalance(), 0.0);
  });

  test('getTotalBalance should sum all account balances', () async {
    final acc1 = AccountModel.create(name: 'Acc1', bank: 'B1')..id = 1;
    final acc2 = AccountModel.create(name: 'Acc2', bank: 'B2')..id = 2;

    when(() => mockAccountRepo.getAll()).thenReturn([acc1, acc2]);

    final rev1 = RevenueModel.create(
      name: 'R1',
      amount: 100,
      accountId: 1,
      date: DateTime.now(),

    );

    final rev2 = RevenueModel.create(
      name: 'R2',
      amount: 50,
      accountId: 2,
      date: DateTime.now(),

    );

    when(() => mockRevenueRepo.getAll()).thenReturn([rev1, rev2]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(accountProvider.future);

    expect(container.read(accountProvider.notifier).getTotalBalance(), 150.0);
  });
}
