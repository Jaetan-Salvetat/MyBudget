import 'package:mybudget/core/repositories/recurring_transaction_repository.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/objectbox.g.dart';

class RevenueRepository extends RecurringTransactionRepository<RevenueModel> {
  RevenueRepository(Box<RevenueModel> box)
    : super(
        box,
        RevenueModel_.id,
        RevenueModel_.endDate,
        RevenueModel_.parentId,
      );
}
