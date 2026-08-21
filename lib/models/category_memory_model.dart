import 'package:objectbox/objectbox.dart';

/// A category the user picked for a given piece of text.
///
/// Replayed after the model to make sure a correction is only ever made once.
@Entity()
class CategoryMemoryModel {
  /// Number of user edits after which [slug] stops being updated.
  static const int freezeAfterCorrections = 5;

  @Id()
  int id = 0;

  /// Normalised text, see [CategoryMemoryService.normalizeKey].
  @Unique()
  late String key;

  late String slug;

  /// How many times the user picked a category for this key.
  int corrections = 1;

  /// Whether the memory is applied for this key.
  ///
  /// Flipped to false on the [freezeAfterCorrections]th edit, and nowhere else.
  bool useMemory = true;

  @Property(type: PropertyType.date)
  late DateTime updatedAt;

  CategoryMemoryModel();

  CategoryMemoryModel.create({
    required this.key,
    required this.slug,
    required this.updatedAt,
  });

  factory CategoryMemoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryMemoryModel()
      ..key = json['key'] as String? ?? ''
      ..slug = json['slug'] as String? ?? ''
      ..corrections = json['corrections'] as int? ?? 1
      ..useMemory = json['useMemory'] as bool? ?? true
      ..updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'slug': slug,
        'corrections': corrections,
        'useMemory': useMemory,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// True once the user has edited this key enough times that it is no longer
  /// trusted: the slug stops being updated and the memory stops answering.
  bool get isFrozen => corrections >= freezeAfterCorrections;
}
