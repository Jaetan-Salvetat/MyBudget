import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/objectbox.g.dart';

class ExpenseRepository {
  final Box<ExpenseModel> _box;

  ExpenseRepository(this._box);

  List<ExpenseModel> getAll() {
    return _box.getAll();
  }

  ExpenseModel? get(int id) {
    return _box.get(id);
  }

  List<ExpenseModel> getActive() {
    final query = _box.query(ExpenseModel_.endDate.isNull()).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<ExpenseModel> getClosed() {
    final query = _box.query(ExpenseModel_.endDate.notNull()).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<ExpenseModel> getChain(int rootId) {
    final query = _box
        .query(ExpenseModel_.parentId.equals(rootId) |
            ExpenseModel_.id.equals(rootId))
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  int add(ExpenseModel expense) {
    return _box.put(expense);
  }

  int update(ExpenseModel expense) {
    return _box.put(expense);
  }

  bool delete(int id) {
    return _box.remove(id);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
