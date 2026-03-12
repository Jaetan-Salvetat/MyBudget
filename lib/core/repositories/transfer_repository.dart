import 'package:mybudget/models/transfer_model.dart';
import 'package:objectbox/objectbox.dart';

class TransferRepository {
  final Box<TransferModel> _box;

  TransferRepository(this._box);

  List<TransferModel> getAll() {
    return _box.getAll();
  }

  int add(TransferModel transfer) {
    return _box.put(transfer);
  }

  int update(TransferModel transfer) {
    return _box.put(transfer);
  }

  bool delete(int id) {
    return _box.remove(id);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
