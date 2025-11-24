import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseViewModel extends Mock implements ExpenseViewModel {}

class MockRevenueViewModel extends Mock implements RevenueViewModel {}

class MockLoanViewModel extends Mock implements LoanViewModel {}

void main() {
  late AccountViewModel viewModel;
  late MockAccountRepository mockAccountRepository;
  late MockExpenseViewModel mockExpenseViewModel;
  late MockRevenueViewModel mockRevenueViewModel;
  late MockLoanViewModel mockLoanViewModel;

  setUp(() {
    mockAccountRepository = MockAccountRepository();
    mockExpenseViewModel = MockExpenseViewModel();
    mockRevenueViewModel = MockRevenueViewModel();
    mockLoanViewModel = MockLoanViewModel();

    when(() => mockExpenseViewModel.addListener(any())).thenReturn(null);
    when(() => mockRevenueViewModel.addListener(any())).thenReturn(null);
    when(() => mockLoanViewModel.addListener(any())).thenReturn(null);
    when(() => mockExpenseViewModel.removeListener(any())).thenReturn(null);
    when(() => mockRevenueViewModel.removeListener(any())).thenReturn(null);
    when(() => mockLoanViewModel.removeListener(any())).thenReturn(null);

    when(() => mockAccountRepository.getAll()).thenReturn([]);

    viewModel = AccountViewModel(
      mockAccountRepository,
      mockExpenseViewModel,
      mockRevenueViewModel,
      mockLoanViewModel,
    );
  });

  test(
    'getAccountBalance should calculate monthly remaining budget correctly',
    () {
      const int accountId = 1;

      final revenue = RevenueModel.create(
        name: 'Salary',
        amount: 2000,
        accountId: accountId,
        date: DateTime.now(),
        isRegular: true,
      );
      when(() => mockRevenueViewModel.revenues).thenReturn([revenue]);

      final expense = ExpenseModel.create(
        name: 'Groceries',
        amount: 500,
        accountId: accountId,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
      );
      when(() => mockExpenseViewModel.expenses).thenReturn([expense]);

      final loan = LoanModel.create(
        name: 'Car Loan',
        amount: 5000,
        monthlyPayment: 100,
        accountId: accountId,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        dayOfMonth: 1,
        lenderName: 'Bank',
      );

      when(() => mockLoanViewModel.loans).thenReturn([loan]);

      final balance = viewModel.getAccountBalance(accountId);

      expect(balance, 1400.0);
    },
  );

  test('getTotalBalance should sum all account balances', () {
    final acc1 = AccountModel.create(name: 'Acc1', bank: 'B1')..id = 1;
    final acc2 = AccountModel.create(name: 'Acc2', bank: 'B2')..id = 2;

    when(() => mockAccountRepository.getAll()).thenReturn([acc1, acc2]);

    final newViewModel = AccountViewModel(
      mockAccountRepository,
      mockExpenseViewModel,
      mockRevenueViewModel,
      mockLoanViewModel,
    );

    final rev1 = RevenueModel.create(
      name: 'R1',
      amount: 100,
      accountId: 1,
      date: DateTime.now(),
      isRegular: true,
    );

    final rev2 = RevenueModel.create(
      name: 'R2',
      amount: 50,
      accountId: 2,
      date: DateTime.now(),
      isRegular: true,
    );

    when(() => mockRevenueViewModel.revenues).thenReturn([rev1, rev2]);
    when(() => mockExpenseViewModel.expenses).thenReturn([]);
    when(() => mockLoanViewModel.loans).thenReturn([]);

    expect(newViewModel.getTotalBalance(), 150.0);
  });
}
