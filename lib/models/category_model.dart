import 'package:flutter/material.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class CategoryModel {
  @Id()
  int id = 0;  

  @Index()
  late String name;

  late String icon;

  int color = 0xFF2196F3;

  CategoryModel();

  CategoryModel.create({
    required this.name,
    required this.icon,
    this.color = 0xFF2196F3,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final model =
        CategoryModel()
          ..name = json['name'] ?? ''
          ..icon = json['icon'] ?? ''
          ..color = json['color'] ?? 0xFF2196F3;

    if (json['id'] != null) {
      model.id = int.tryParse(json['id'].toString()) ?? 0;
    }

    return model;
  }

  CategoryModel copyWith({String? name, String? icon, int? color}) {
    final model =
        CategoryModel()
          ..id = id
          ..name = name ?? this.name
          ..icon = icon ?? this.icon
          ..color = color ?? this.color;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'icon': icon,
      'color': color,
    };
  }

  IconData getIconData() {
    return CategoryDefaults.resolveIcon(icon);
  }
}
