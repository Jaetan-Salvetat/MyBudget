import 'package:mybudget/models/expense_model.dart';
import 'package:objectbox/objectbox.dart';

class ExpenseRepository {
  final Box<ExpenseModel> _box;

  ExpenseRepository(this._box);

  List<ExpenseModel> getAll() {
    return _box.getAll();
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
