import 'package:objectbox/objectbox.dart';

/// User customisation of a taxonomy node.
///
/// Rows exist only for nodes the user actually renamed or restyled: the
/// taxonomy asset stays the source of truth for everything else.
@Entity()
class CategoryOverrideModel {
  @Id()
  int id = 0;

  @Unique()
  late String slug;

  String? name;

  String? icon;

  int? color;

  CategoryOverrideModel();

  CategoryOverrideModel.create({
    required this.slug,
    String? name,
    this.icon,
    this.color,
  }) : name = _normalizeName(name);

  factory CategoryOverrideModel.fromJson(Map<String, dynamic> json) {
    final model = CategoryOverrideModel()
      ..slug = json['slug'] as String? ?? ''
      ..name = _normalizeName(json['name'] as String?)
      ..icon = json['icon'] as String?
      ..color = json['color'] as int?;

    final id = json['id'];
    if (id != null) model.id = int.tryParse(id.toString()) ?? 0;

    return model;
  }

  bool get isEmpty => name == null && icon == null && color == null;

  CategoryOverrideModel copyWith({String? name, String? icon, int? color}) {
    return CategoryOverrideModel()
      ..id = id
      ..slug = slug
      ..name = _normalizeName(name) ?? this.name
      ..icon = icon ?? this.icon
      ..color = color ?? this.color;
  }

  Map<String, dynamic> toJson() => {
        'id': id.toString(),
        'slug': slug,
        'name': name,
        'icon': icon,
        'color': color,
      };

  static String? _normalizeName(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
