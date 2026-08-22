import 'package:mybudget/models/loan_event_model.dart';
import 'package:objectbox/objectbox.dart';

class LoanEventRepository {
  final Box<LoanEventModel> _box;

  LoanEventRepository(this._box);

  List<LoanEventModel> getAll() {
    return _box.getAll();
  }

  List<LoanEventModel> getForLoan(int loanId) {
    return _box.getAll().where((event) => event.loanId == loanId).toList();
  }

  int add(LoanEventModel event) {
    return _box.put(event);
  }

  int update(LoanEventModel event) {
    return _box.put(event);
  }

  bool delete(int id) {
    return _box.remove(id);
  }

  void deleteForLoan(int loanId) {
    final ids = getForLoan(loanId).map((event) => event.id).toList();
    _box.removeMany(ids);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
