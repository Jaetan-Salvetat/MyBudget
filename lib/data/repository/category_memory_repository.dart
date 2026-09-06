import 'package:mybudget/data/model/category_memory_model.dart';
import 'package:mybudget/objectbox.g.dart';

class CategoryMemoryRepository {
  CategoryMemoryRepository(Store store) : _box = Box<CategoryMemoryModel>(store);

  final Box<CategoryMemoryModel> _box;

  CategoryMemoryModel? get(String key) {
    final query = _box.query(CategoryMemoryModel_.key.equals(key)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  List<CategoryMemoryModel> getAll() => _box.getAll();

  int count() => _box.count();

  void put(CategoryMemoryModel entry) => _box.put(entry);

  void evictOldest(int count) {
    if (count <= 0) return;
    final query = (_box.query()..order(CategoryMemoryModel_.updatedAt)).build();
    try {
      final ids = query.find().take(count).map((entry) => entry.id).toList();
      _box.removeMany(ids);
    } finally {
      query.close();
    }
  }

  void delete(String key) {
    final existing = get(key);
    if (existing != null) _box.remove(existing.id);
  }

  void deleteAll() => _box.removeAll();
}
