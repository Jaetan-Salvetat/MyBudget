import 'package:objectbox/objectbox.dart';

@Entity()
class CategoryMemoryModel {
  static const int freezeAfterCorrections = 5;

  @Id()
  int id = 0;

  @Unique()
  late String key;

  late String slug;

  int corrections = 1;

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
      ..updatedAt =
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'slug': slug,
    'corrections': corrections,
    'useMemory': useMemory,
    'updatedAt': updatedAt.toIso8601String(),
  };

  bool get isFrozen => corrections >= freezeAfterCorrections;
}
