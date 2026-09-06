import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:objectbox/objectbox.dart';

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
    String? icon,
    this.color,
  }) : name = _normalizeName(name),
       icon = CategoryDefaults.canonicalIconKey(icon);

  factory CategoryOverrideModel.fromJson(Map<String, dynamic> json) {
    final model = CategoryOverrideModel()
      ..slug = json['slug'] as String? ?? ''
      ..name = _normalizeName(json['name'] as String?)
      ..icon = CategoryDefaults.canonicalIconKey(json['icon'] as String?)
      ..color = json['color'] as int?;

    final id = json['id'];
    if (id != null) model.id = int.tryParse(id.toString()) ?? 0;

    return model;
  }

  bool get isEmpty => name == null && icon == null && color == null;

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
