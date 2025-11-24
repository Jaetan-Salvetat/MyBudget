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
  late MockExpenseRepository mockExpenseRepo;
  late MockCategoryRepository mockCategoryRepo;

  setUp(() {
    mockExpenseRepo = MockExpenseRepository();
    mockCategoryRepo = MockCategoryRepository();
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    viewModel = ExpenseViewModel(mockExpenseRepo, mockCategoryRepo);
  });

  test(
    'getTotalExpenses (Annual DateBased) should include last day of month',
    () async {
      final now = DateTime.now();
      final endOfMonthDate = DateTime(now.year, now.month + 1, 0, 23, 0);

      final expense = ExpenseModel.create(
        name: 'Annual End Month',
        amount: 1200,
        categoryId: 1,
        date: endOfMonthDate,
        frequency: 'Annuel',
        accountId: 1,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      await viewModel.loadExpenses();

      final total = viewModel.getTotalExpenses(
        null,
        AnnualExpenseCalculationMode.dateBasedOnly,
      );

      expect(
        total,
        1200.0,
        reason:
            'Should include annual expense falling on the last moment of the month',
      );
    },
  );

  test('getTotalExpenses (Annual Amortized) should divide by 12', () async {
    final expense = ExpenseModel.create(
      name: 'Annual',
      amount: 1200,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Annuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
    await viewModel.loadExpenses();

    final total = viewModel.getTotalExpenses(
      null,
      AnnualExpenseCalculationMode.monthlyAmortized,
    );

    expect(total, 100.0);
  });

  test('getTotalExpenses (Monthly) should sum directly', () async {
    final expense = ExpenseModel.create(
      name: 'Monthly',
      amount: 100,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
    await viewModel.loadExpenses();

    final total = viewModel.getTotalExpenses(
      null,
      AnnualExpenseCalculationMode.dateBasedOnly,
    );

    expect(total, 100.0);
  });
}
