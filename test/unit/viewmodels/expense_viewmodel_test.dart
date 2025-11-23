import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late ExpenseViewModel viewModel;
  late MockExpenseRepository mockExpenseRepository;
  late MockCategoryRepository mockCategoryRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockCategoryRepository = MockCategoryRepository();

    // Default behavior
    when(() => mockExpenseRepository.getAll()).thenReturn([]);

    viewModel = ExpenseViewModel(mockExpenseRepository, mockCategoryRepository);
  });

  group('ExpenseViewModel', () {
    test('initial load should fetch expenses', () async {
      verify(() => mockExpenseRepository.getAll()).called(1);
      expect(viewModel.expenses, isEmpty);
      expect(viewModel.isLoading, false);
    });

    test('addExpense should call repository and reload', () async {
      final expense = ExpenseModel.create(
        name: 'New Expense',
        amount: 10.0,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
        accountId: 1,
      );

      when(() => mockExpenseRepository.add(expense)).thenReturn(1);
      when(() => mockExpenseRepository.getAll()).thenReturn([expense]);

      await viewModel.addExpense(expense);

      verify(() => mockExpenseRepository.add(expense)).called(1);
      verify(() => mockExpenseRepository.getAll()).called(2); // Init + Reload
      expect(viewModel.expenses.length, 1);
    });

    test('deleteExpense should call repository and reload', () async {
      when(() => mockExpenseRepository.delete(1)).thenReturn(true);

      await viewModel.deleteExpense(1);

      verify(() => mockExpenseRepository.delete(1)).called(1);
      verify(() => mockExpenseRepository.getAll()).called(2); // Init + Reload
    });

    test('getTotalExpenses should calculate correctly', () {
      final expense1 = ExpenseModel.create(
        name: 'E1',
        amount: 100.0,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
        accountId: 1,
      );
      final expense2 = ExpenseModel.create(
        name: 'E2',
        amount: 1200.0,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Annuel',
        accountId: 1,
      );

      // Monthly Amortized: 100 + (1200 / 12) = 200
      final total = viewModel.getTotalExpenses([
        expense1,
        expense2,
      ], AnnualExpenseCalculationMode.monthlyAmortized);

      expect(total, 200.0);
    });
  });
}
