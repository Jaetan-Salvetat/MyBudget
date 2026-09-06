import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/utils/text_normalizer.dart';
import 'package:mybudget/models/category_memory_model.dart';

class CategoryMemoryService {
  static const int maxEntries = 500;

  final CategoryMemoryRepository _repository;
  final DateTime Function() _now;

  CategoryMemoryService(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static String normalizeKey(String text) => TextNormalizer.normalize(text);

  String? recall(String text) {
    final key = normalizeKey(text);
    if (key.isEmpty) return null;

    final entry = _repository.get(key);
    if (entry == null || !entry.useMemory) return null;
    return entry.slug;
  }

  void remember(String text, String slug) {
    final key = normalizeKey(text);
    if (key.isEmpty) return;

    final existing = _repository.get(key);
    if (existing == null) {
      _evictIfFull();
      _repository.put(
        CategoryMemoryModel.create(key: key, slug: slug, updatedAt: _now()),
      );
      return;
    }

    existing
      ..corrections += 1
      ..updatedAt = _now();
    if (existing.isFrozen) {
      existing.useMemory = false;
    } else {
      existing.slug = slug;
    }
    _repository.put(existing);
  }

  void forget(String text) => _repository.delete(normalizeKey(text));

  void _evictIfFull() {
    final overflow = _repository.count() - maxEntries + 1;
    if (overflow > 0) _repository.evictOldest(overflow);
  }
}
