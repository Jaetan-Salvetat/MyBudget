import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/objectbox.g.dart';

class CategoryOverrideRepository {
  final Box<CategoryOverrideModel> _box;

  CategoryOverrideRepository(this._box);

  Map<String, CategoryOverrideModel> getAll() {
    return {for (final override in _box.getAll()) override.slug: override};
  }

  CategoryOverrideModel? get(String slug) {
    final query = _box
        .query(CategoryOverrideModel_.slug.equals(slug))
        .build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  /// Stores the override, or removes it when nothing is customised anymore.
  void save(CategoryOverrideModel override) {
    final existing = get(override.slug);

    if (override.isEmpty) {
      if (existing != null) _box.remove(existing.id);
      return;
    }

    _box.put(override..id = existing?.id ?? 0);
  }

  void delete(String slug) {
    final existing = get(slug);
    if (existing != null) _box.remove(existing.id);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
