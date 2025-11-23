import 'package:mybudget/models/revenue_model.dart';
import 'package:objectbox/objectbox.dart';

class RevenueRepository {
  final Box<RevenueModel> _box;

  RevenueRepository(this._box);

  List<RevenueModel> getAll() {
    return _box.getAll();
  }

  int add(RevenueModel revenue) {
    return _box.put(revenue);
  }

  int update(RevenueModel revenue) {
    return _box.put(revenue);
  }

  bool delete(int id) {
    return _box.remove(id);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
