import 'package:mybudget/data/model/loan_model.dart';
import 'package:mybudget/objectbox.g.dart';

class LoanRepository {
  LoanRepository(Store store) : _box = Box<LoanModel>(store);

  final Box<LoanModel> _box;

  List<LoanModel> getAll() {
    return _box.getAll();
  }

  LoanModel? get(int id) {
    return _box.get(id);
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
