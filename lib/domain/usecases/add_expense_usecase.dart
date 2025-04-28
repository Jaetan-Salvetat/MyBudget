import 'package:mybudget/core/usecases/usecase.dart';
import 'package:mybudget/domain/entities/expense.dart';
import 'package:mybudget/domain/repositories/expense_repository.dart';

class AddExpenseUseCase implements UseCase<void, AddExpenseParams> {
  final ExpenseRepository expenseRepository;

  AddExpenseUseCase(this.expenseRepository);

  @override
  Future<void> call(AddExpenseParams params) async {
    await expenseRepository.addExpense(params.expense);
  }
}

class AddExpenseParams {
  final Expense expense;

  AddExpenseParams({required this.expense});
}