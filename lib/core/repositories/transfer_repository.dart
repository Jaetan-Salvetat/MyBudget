import 'package:mybudget/core/repositories/recurring_transaction_repository.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/objectbox.g.dart';

class TransferRepository extends RecurringTransactionRepository<TransferModel> {
  TransferRepository(Box<TransferModel> box)
    : super(
        box,
        TransferModel_.id,
        TransferModel_.endDate,
        TransferModel_.parentId,
      );
}
