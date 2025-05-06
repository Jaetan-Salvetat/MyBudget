import 'package:isar/isar.dart';
import 'package:mybudget/domain/entities/category.dart';

part 'category_model.g.dart';

@collection
class CategoryModel implements Category {
  Id id = Isar.autoIncrement;
  
  @Index(type: IndexType.value)
  late String name;
  
  late String icon;

  CategoryModel();
  
  CategoryModel.create({
    required this.name,
    required this.icon,
  });
  
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final model = CategoryModel()
      ..name = json['name'] ?? ''
      ..icon = json['icon'] ?? '';
    
    if (json['id'] != null) {
      model.id = int.parse(json['id'].toString());
    }
    
    return model;
  }
  
  CategoryModel copyWith({
    String? name,
    String? icon,
  }) {
    final model = CategoryModel()
      ..id = id
      ..name = name ?? this.name
      ..icon = icon ?? this.icon;
    return model;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'icon': icon,
    };
  }
}
