import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/models/transaction_event_model.dart';
import 'package:mybudget/objectbox.g.dart';

class TransactionEventRepository {
  TransactionEventRepository(this._box);
  final Box<TransactionEventModel> _box;

  List<TransactionEventModel> getForRoot(int rootId, TransactionType type) {
    final query = _box
        .query(TransactionEventModel_.rootId.equals(rootId))
        .build();
    try {
      return query.find().where((event) => event.typeEnum == type).toList();
    } finally {
      query.close();
    }
  }

  void add(TransactionEventModel event) {
    _box.put(event);
  }

  void deleteForRoot(int rootId, TransactionType type) {
    _box.removeMany([for (final event in getForRoot(rootId, type)) event.id]);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
