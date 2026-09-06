import 'package:mybudget/core/repositories/recurring_transaction_repository.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/objectbox.g.dart';

class ExpenseRepository extends RecurringTransactionRepository<ExpenseModel> {
  ExpenseRepository(Box<ExpenseModel> box)
    : super(
        box,
        ExpenseModel_.id,
        ExpenseModel_.endDate,
        ExpenseModel_.parentId,
      );
}
