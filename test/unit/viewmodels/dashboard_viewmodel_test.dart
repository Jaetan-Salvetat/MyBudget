import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/dashboard/dashboard_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/settings/settings_viewmodel.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';

class MockAccountViewModel extends Mock implements AccountViewModel {}

class MockExpenseViewModel extends Mock implements ExpenseViewModel {}

class MockRevenueViewModel extends Mock implements RevenueViewModel {}

class MockLoanViewModel extends Mock implements LoanViewModel {}

class MockSettingsViewModel extends Mock implements SettingsViewModel {}

void main() {
  late DashboardViewModel viewModel;
  late MockAccountViewModel mockAccountVM;
  late MockExpenseViewModel mockExpenseVM;
  late MockRevenueViewModel mockRevenueVM;
  late MockLoanViewModel mockLoanVM;
  late MockSettingsViewModel mockSettingsVM;

  setUpAll(() {
    registerFallbackValue(AnnualExpenseCalculationMode.monthlyAmortized);
  });

  setUp(() {
    mockAccountVM = MockAccountViewModel();
    mockExpenseVM = MockExpenseViewModel();
    mockRevenueVM = MockRevenueViewModel();
    mockLoanVM = MockLoanViewModel();
    mockSettingsVM = MockSettingsViewModel();

    when(() => mockAccountVM.addListener(any())).thenReturn(null);
    when(() => mockExpenseVM.addListener(any())).thenReturn(null);
    when(() => mockRevenueVM.addListener(any())).thenReturn(null);
    when(() => mockLoanVM.addListener(any())).thenReturn(null);
    when(() => mockSettingsVM.addListener(any())).thenReturn(null);
    when(() => mockAccountVM.removeListener(any())).thenReturn(null);
    when(() => mockExpenseVM.removeListener(any())).thenReturn(null);
    when(() => mockRevenueVM.removeListener(any())).thenReturn(null);
    when(() => mockLoanVM.removeListener(any())).thenReturn(null);
    when(() => mockSettingsVM.removeListener(any())).thenReturn(null);

    when(
      () => mockSettingsVM.annualExpenseCalculationMode,
    ).thenReturn(AnnualExpenseCalculationMode.monthlyAmortized);

    viewModel = DashboardViewModel(
      mockAccountVM,
      mockExpenseVM,
      mockRevenueVM,
      mockLoanVM,
      mockSettingsVM,
    );
  });

  test(
    'categorySummaries should calculate percentages relative to Total Expenses + Loans',
    () {
      final catFood = CategoryModel.create(
        name: 'Food',
        icon: 'fastfood',
        color: 0xFF0000,
      );
      final catTransport = CategoryModel.create(
        name: 'Transport',
        icon: 'car',
        color: 0xFF0000,
      );

      when(
        () => mockExpenseVM.getExpensesByCategory(),
      ).thenReturn({catFood: 600.0, catTransport: 200.0});

      when(() => mockLoanVM.getTotalMonthlyPayments()).thenReturn(200.0);

      when(() => mockExpenseVM.getMonthlyExpenses(any())).thenReturn(800.0);

      final summaries = viewModel.categorySummaries;

      expect(summaries.length, 2);

      final foodSummary = summaries.firstWhere((s) => s.categoryName == 'Food');
      expect(foodSummary.percentage, 0.6);

      final transportSummary = summaries.firstWhere(
        (s) => s.categoryName == 'Transport',
      );
      expect(transportSummary.percentage, 0.2);
    },
  );
}
