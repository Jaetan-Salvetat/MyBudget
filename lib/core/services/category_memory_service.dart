import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/utils/text_normalizer.dart';
import 'package:mybudget/models/category_memory_model.dart';

/// Replays the categories the user picked, so a model mistake is corrected once.
///
/// Applied *after* the model rather than instead of it: the correction only ever
/// concerned the category, and the type and recurrence heads must keep running.
class CategoryMemoryService {
  /// Upper bound on stored entries; the least recently used are evicted.
  static const int maxEntries = 500;

  final CategoryMemoryRepository _repository;
  final DateTime Function() _now;

  CategoryMemoryService(
    this._repository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Lowercases, strips accents and collapses whitespace.
  ///
  /// Matching is exact on the result: "macdo" does not recall "macdo avec Paul".
  /// Token matching would generalise but a silent false positive is worse than
  /// a miss.
  static String normalizeKey(String text) => TextNormalizer.normalize(text);

  /// The remembered slug for [text], or null when nothing applies.
  String? recall(String text) {
    final key = normalizeKey(text);
    if (key.isEmpty) return null;

    final entry = _repository.get(key);
    if (entry == null || !entry.useMemory) return null;
    return entry.slug;
  }

  /// Records the category the user picked for [text].
  ///
  /// On the [CategoryMemoryModel.freezeAfterCorrections]th edit the entry is
  /// retired: the slug stops being updated and [CategoryMemoryModel.useMemory]
  /// flips to false. A key the user keeps changing has no single right answer,
  /// and replaying the latest guess with confidence is worse than not answering.
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
