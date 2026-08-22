import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/objectbox.g.dart';

class RevenueRepository {
  final Box<RevenueModel> _box;

  RevenueRepository(this._box);

  List<RevenueModel> getAll() {
    return _box.getAll();
  }

  RevenueModel? get(int id) {
    return _box.get(id);
  }

  List<RevenueModel> getActive() {
    final query = _box.query(RevenueModel_.endDate.isNull()).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<RevenueModel> getClosed() {
    final query = _box.query(RevenueModel_.endDate.notNull()).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<RevenueModel> getChain(int rootId) {
    final query = _box
        .query(
          RevenueModel_.parentId.equals(rootId) |
              RevenueModel_.id.equals(rootId),
        )
        .build();
    final results = query.find();
    query.close();
    return results;
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
