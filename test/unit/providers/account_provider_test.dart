import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/transfer_model.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockTransferRepository extends Mock implements TransferRepository {}

void main() {
  late MockAccountRepository mockAccountRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late MockLoanEventRepository mockLoanEventRepo;
  late MockTransferRepository mockTransferRepo;

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockLoanEventRepo = MockLoanEventRepository();
    when(() => mockLoanEventRepo.getAll()).thenReturn([]);
    mockTransferRepo = MockTransferRepository();

    when(() => mockAccountRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getActive()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getActive()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockTransferRepo.getAll()).thenReturn([]);
    when(() => mockTransferRepo.getActive()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        revenueRepositoryProvider.overrideWithValue(mockRevenueRepo),
        loanRepositoryProvider.overrideWithValue(mockLoanRepo),
        loanEventRepositoryProvider.overrideWithValue(mockLoanEventRepo),
        transferRepositoryProvider.overrideWithValue(mockTransferRepo),
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
        startDate: DateTime.now(),
        frequency: 'Mensuel',
      );
      when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
      when(() => mockRevenueRepo.getActive()).thenReturn([revenue]);

      final expense = ExpenseModel.create(
        name: 'Groceries',
        amount: 500,
        accountId: accountId,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: 'Mensuel',
      );
      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);

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
      await container.read(transferProvider.future);
      await container.read(accountProvider.future);

      final balance = container
          .read(accountProvider.notifier)
          .getAccountBalance(accountId);

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
    await container.read(transferProvider.future);
    await container.read(accountProvider.future);

    expect(
      container.read(accountProvider.notifier).getAccountBalance(accountId),
      0.0,
    );
  });

  test(
    'getAccountBalance returns negative value when expenses exceed revenues',
    () async {
      const int accountId = 1;

      final revenue = RevenueModel.create(
        name: 'Small income',
        amount: 100,
        accountId: accountId,
        startDate: DateTime.now(),
        frequency: 'Mensuel',
      );
      final expense = ExpenseModel.create(
        name: 'Big expense',
        amount: 800,
        accountId: accountId,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: 'Mensuel',
      );

      when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
      when(() => mockRevenueRepo.getActive()).thenReturn([revenue]);
      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockExpenseRepo.getActive()).thenReturn([expense]);
      when(() => mockLoanRepo.getAll()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);
      await container.read(revenueProvider.future);
      await container.read(loanProvider.future);
      await container.read(transferProvider.future);
      await container.read(accountProvider.future);

      final balance = container
          .read(accountProvider.notifier)
          .getAccountBalance(accountId);
      expect(balance, -700.0);
    },
  );

  test('getAccountBalance includes outgoing transfer in balance', () async {
    const int accountId = 1;

    final revenue = RevenueModel.create(
      name: 'Salary',
      amount: 2000,
      accountId: accountId,
      startDate: DateTime.now(),
      frequency: 'Mensuel',
    );
    when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
    when(() => mockRevenueRepo.getActive()).thenReturn([revenue]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);

    final transfer = TransferModel.create(
      name: 'Epargne',
      amount: 500,
      fromAccountId: accountId,
      toAccountId: 2,
      startDate: DateTime.now(),
      frequency: 'Mensuel',
    );
    when(() => mockTransferRepo.getAll()).thenReturn([transfer]);
    when(() => mockTransferRepo.getActive()).thenReturn([transfer]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(transferProvider.future);
    await container.read(accountProvider.future);

    final balance = container
        .read(accountProvider.notifier)
        .getAccountBalance(accountId);
    expect(balance, 1500.0);
  });

  test('getAccountBalance includes incoming transfer in balance', () async {
    const int accountId = 1;

    final revenue = RevenueModel.create(
      name: 'Salary',
      amount: 2000,
      accountId: accountId,
      startDate: DateTime.now(),
      frequency: 'Mensuel',
    );
    when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
    when(() => mockRevenueRepo.getActive()).thenReturn([revenue]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);

    final transfer = TransferModel.create(
      name: 'Remboursement',
      amount: 300,
      fromAccountId: 2,
      toAccountId: accountId,
      startDate: DateTime.now(),
      frequency: 'Mensuel',
    );
    when(() => mockTransferRepo.getAll()).thenReturn([transfer]);
    when(() => mockTransferRepo.getActive()).thenReturn([transfer]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(transferProvider.future);
    await container.read(accountProvider.future);

    final balance = container
        .read(accountProvider.notifier)
        .getAccountBalance(accountId);
    expect(balance, 2300.0);
  });
}
