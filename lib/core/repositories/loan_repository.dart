import 'package:mybudget/models/loan_model.dart';
import 'package:objectbox/objectbox.dart';

class LoanRepository {
  LoanRepository(this._box);
  final Box<LoanModel> _box;

  List<LoanModel> getAll() {
    return _box.getAll();
  }

  int add(LoanModel loan) {
    return _box.put(loan);
  }

  int update(LoanModel loan) {
    return _box.put(loan);
  }

  bool delete(int id) {
    return _box.remove(id);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
