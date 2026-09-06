import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/repository/recurring_transaction_repository.dart';
import 'package:mybudget/objectbox.g.dart';

class RevenueRepository extends RecurringTransactionRepository<RevenueModel> {
  RevenueRepository(Store store)
    : super(
        Box<RevenueModel>(store),
        RevenueModel_.id,
        RevenueModel_.endDate,
        RevenueModel_.parentId,
      );
}
