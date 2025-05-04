import 'package:mybudget/domain/entities/category.dart';

class CategoryModel implements Category {
  final String _id;
  final String _name;
  final String _icon;

  CategoryModel({
    required String id,
    required String name,
    required String icon,
  })  : _id = id,
        _name = name,
        _icon = icon;

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  String get icon => _icon;
  
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}
