import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/objectbox.g.dart';

class TransferRepository {
  final Box<TransferModel> _box;

  TransferRepository(this._box);

  List<TransferModel> getAll() {
    return _box.getAll();
  }

  TransferModel? get(int id) {
    return _box.get(id);
  }

  List<TransferModel> getActive() {
    final query = _box.query(TransferModel_.endDate.isNull()).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<TransferModel> getClosed() {
    final query = _box.query(TransferModel_.endDate.notNull()).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<TransferModel> getChain(int rootId) {
    final query = _box
        .query(TransferModel_.parentId.equals(rootId) |
            TransferModel_.id.equals(rootId))
        .build();
    final results = query.find();
    query.close();
    return results;
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
