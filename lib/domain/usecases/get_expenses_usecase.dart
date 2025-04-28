import 'package:mybudget/core/usecases/usecase.dart';
import 'package:mybudget/domain/entities/expense.dart';
import 'package:mybudget/domain/repositories/expense_repository.dart';

class GetExpensesUseCase extends UseCase<List<Expense>, void> {
  final ExpenseRepository repository;

  GetExpensesUseCase(this.repository);

  @override
  Future<List<Expense>> call(void params) async {
    return await repository.getExpenses();
  }
}