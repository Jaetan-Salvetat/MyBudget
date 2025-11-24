import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/dashboard/dashboard_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/settings/settings_viewmodel.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';

class MockAccountViewModel extends Mock implements AccountViewModel {}

class MockExpenseViewModel extends Mock implements ExpenseViewModel {}

class MockRevenueViewModel extends Mock implements RevenueViewModel {}

class MockLoanViewModel extends Mock implements LoanViewModel {}

class MockSettingsViewModel extends Mock implements SettingsViewModel {}

void main() {
  late DashboardViewModel viewModel;
  late MockAccountViewModel mockAccountViewModel;
  late MockExpenseViewModel mockExpenseViewModel;
  late MockRevenueViewModel mockRevenueViewModel;
  late MockLoanViewModel mockLoanViewModel;
  late MockSettingsViewModel mockSettingsViewModel;

  setUpAll(() {
    registerFallbackValue(AnnualExpenseCalculationMode.monthlyAmortized);
  });

  setUp(() {
    mockAccountViewModel = MockAccountViewModel();
    mockExpenseViewModel = MockExpenseViewModel();
    mockRevenueViewModel = MockRevenueViewModel();
    mockLoanViewModel = MockLoanViewModel();
    mockSettingsViewModel = MockSettingsViewModel();

    when(() => mockAccountViewModel.addListener(any())).thenReturn(null);
    when(() => mockExpenseViewModel.addListener(any())).thenReturn(null);
    when(() => mockRevenueViewModel.addListener(any())).thenReturn(null);
    when(() => mockLoanViewModel.addListener(any())).thenReturn(null);
    when(() => mockSettingsViewModel.addListener(any())).thenReturn(null);
    when(() => mockAccountViewModel.removeListener(any())).thenReturn(null);
    when(() => mockExpenseViewModel.removeListener(any())).thenReturn(null);
    when(() => mockRevenueViewModel.removeListener(any())).thenReturn(null);
    when(() => mockLoanViewModel.removeListener(any())).thenReturn(null);
    when(() => mockSettingsViewModel.removeListener(any())).thenReturn(null);

    when(
      () => mockSettingsViewModel.annualExpenseCalculationMode,
    ).thenReturn(AnnualExpenseCalculationMode.monthlyAmortized);

    viewModel = DashboardViewModel(
      mockAccountViewModel,
      mockExpenseViewModel,
      mockRevenueViewModel,
      mockLoanViewModel,
      mockSettingsViewModel,
    );
  });

  group('DashboardViewModel', () {
    test('totalExpenses should sum monthly expenses and loan payments', () {
      when(
        () => mockExpenseViewModel.getMonthlyExpenses(any()),
      ).thenReturn(500.0);
      when(() => mockLoanViewModel.getTotalMonthlyPayments()).thenReturn(200.0);

      expect(viewModel.totalExpenses, 700.0);
    });

    test('netCashFlow should delegate to AccountViewModel', () {
      when(() => mockAccountViewModel.getNetCashFlow(any())).thenReturn(300.0);
      expect(viewModel.netCashFlow, 300.0);
    });

    test('savingsRate should delegate to AccountViewModel', () {
      when(() => mockAccountViewModel.getSavingsRate(any())).thenReturn(15.0);
      expect(viewModel.savingsRate, 15.0);
    });
  });
}
