import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/expense_model.dart';

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

  test('getTotalExpenses (Annual) should divide by 12', () async {
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

    final total = viewModel.getTotalExpenses();

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

    final total = viewModel.getTotalExpenses();

    expect(total, 100.0);
  });

  test('getTotalExpenses should sum monthly and amortized annual', () async {
    final monthly = ExpenseModel.create(
      name: 'Monthly',
      amount: 500,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
      accountId: 1,
    );
    final annual = ExpenseModel.create(
      name: 'Annual',
      amount: 1200,
      categoryId: 1,
      date: DateTime.now(),
      frequency: 'Annuel',
      accountId: 1,
    );

    when(() => mockExpenseRepo.getAll()).thenReturn([monthly, annual]);
    await viewModel.loadExpenses();

    final total = viewModel.getTotalExpenses();

    expect(total, 600.0); // 500 + 1200/12
  });
}
