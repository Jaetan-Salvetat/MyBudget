import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:mybudget/domain/entities/category.dart';

@Entity()
class CategoryModel implements Category {
  @override
  @Id()
  int id = 0; // 0 signifie auto-increment dans ObjectBox

  @override
  @Index()
  late String name;

  @override
  late String icon;

  CategoryModel();

  CategoryModel.create({required this.name, required this.icon});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final model =
        CategoryModel()
          ..name = json['name'] ?? ''
          ..icon = json['icon'] ?? '';

    if (json['id'] != null) {
      model.id = int.parse(json['id'].toString());
    }

    return model;
  }

  CategoryModel copyWith({String? name, String? icon}) {
    final model =
        CategoryModel()
          ..id = id
          ..name = name ?? this.name
          ..icon = icon ?? this.icon;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {'id': id.toString(), 'name': name, 'icon': icon};
  }
  
  IconData getIconData() {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'medical_services':
        return Icons.medical_services;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'school':
        return Icons.school;
      case 'movie':
        return Icons.movie;
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      case 'checkroom':
        return Icons.checkroom;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'shopping_bag':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }
}
