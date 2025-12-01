import 'package:objectbox/objectbox.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/objectbox.g.dart';

class TransferRepository {
  final Box<TransferModel> _box;

  TransferRepository(this._box);

  void create(TransferModel transfer) {
    _box.put(transfer);
  }

  void delete(int id) {
    _box.remove(id);
  }

  List<TransferModel> getByAccount(int accountId) {
    return _box
        .query(
          TransferModel_.sourceAccountId
              .equals(accountId)
              .or(TransferModel_.destinationAccountId.equals(accountId)),
        )
        .build()
        .find();
  }
}
