import 'package:mybudget/models/legacy_category_model.dart';
import 'package:mybudget/objectbox.g.dart';

class LegacyCategoryRepository {
  final Box<LegacyCategoryModel> _box;

  LegacyCategoryRepository(this._box);

  Map<int, String> namesById() {
    return {for (final category in _box.getAll()) category.id: category.name};
  }
}
