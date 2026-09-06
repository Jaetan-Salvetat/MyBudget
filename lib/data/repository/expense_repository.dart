import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/repository/recurring_transaction_repository.dart';
import 'package:mybudget/objectbox.g.dart';

class ExpenseRepository extends RecurringTransactionRepository<ExpenseModel> {
  ExpenseRepository(Store store)
    : super(
        Box<ExpenseModel>(store),
        ExpenseModel_.id,
        ExpenseModel_.endDate,
        ExpenseModel_.parentId,
      );
}
