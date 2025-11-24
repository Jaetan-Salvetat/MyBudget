import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
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

    when(() => mockAccountRepository.getAll()).thenReturn([]);
    when(() => mockExpenseViewModel.expenses).thenReturn([]);
    when(() => mockRevenueViewModel.revenues).thenReturn([]);
    when(() => mockLoanViewModel.loans).thenReturn([]);

    when(() => mockExpenseViewModel.addListener(any())).thenReturn(null);
    when(() => mockRevenueViewModel.addListener(any())).thenReturn(null);
    when(() => mockLoanViewModel.addListener(any())).thenReturn(null);
    when(() => mockExpenseViewModel.removeListener(any())).thenReturn(null);
    when(() => mockRevenueViewModel.removeListener(any())).thenReturn(null);
    when(() => mockLoanViewModel.removeListener(any())).thenReturn(null);

    viewModel = AccountViewModel(
      mockAccountRepository,
      mockExpenseViewModel,
      mockRevenueViewModel,
      mockLoanViewModel,
    );
  });

  group('AccountViewModel', () {
    test('initial load should fetch accounts', () async {
      verify(() => mockAccountRepository.getAll()).called(1);
      expect(viewModel.accounts, isEmpty);
      expect(viewModel.isLoading, false);
    });

    test('addAccount should call repository and reload', () async {
      final account = AccountModel.create(name: 'New Account', bank: 'Bank');

      when(() => mockAccountRepository.add(account)).thenReturn(1);
      when(() => mockAccountRepository.getAll()).thenReturn([account]);

      await viewModel.addAccount(account);

      verify(() => mockAccountRepository.add(account)).called(1);
      verify(() => mockAccountRepository.getAll()).called(2);
      expect(viewModel.accounts.length, 1);
    });

    test('getAccountBalance should calculate correctly', () {
      const accountId = 1;

      final revenue = RevenueModel.create(
        name: 'Salary',
        amount: 1000.0,
        isRegular: true,
        date: DateTime.now(),
        accountId: accountId,
      );
      when(() => mockRevenueViewModel.revenues).thenReturn([revenue]);

      final expense = ExpenseModel.create(
        name: 'Food',
        amount: 200.0,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
        accountId: accountId,
      );
      when(() => mockExpenseViewModel.expenses).thenReturn([expense]);

      final loan = LoanModel.create(
        name: 'Loan',
        amount: 1000.0,
        lenderName: 'Bank',
        dayOfMonth: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        accountId: accountId,
        monthlyPayment: 100.0,
      );
      when(() => mockLoanViewModel.loans).thenReturn([loan]);

      expect(viewModel.getAccountBalance(accountId), 700.0);
    });
  });
}
