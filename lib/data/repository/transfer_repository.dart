import 'package:mybudget/data/model/transfer_model.dart';
import 'package:mybudget/data/repository/recurring_transaction_repository.dart';
import 'package:mybudget/objectbox.g.dart';

class TransferRepository extends RecurringTransactionRepository<TransferModel> {
  TransferRepository(Store store)
    : super(
        Box<TransferModel>(store),
        TransferModel_.id,
        TransferModel_.endDate,
        TransferModel_.parentId,
      );
}
