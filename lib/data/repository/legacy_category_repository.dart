import 'package:mybudget/data/model/legacy_category_model.dart';
import 'package:mybudget/objectbox.g.dart';

class LegacyCategoryRepository {
  LegacyCategoryRepository(Store store) : _box = Box<LegacyCategoryModel>(store);

  final Box<LegacyCategoryModel> _box;

  Map<int, String> namesById() {
    return {for (final category in _box.getAll()) category.id: category.name};
  }

  void deleteAll() {
    _box.removeAll();
  }
}
