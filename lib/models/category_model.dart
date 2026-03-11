import 'package:flutter/material.dart';
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
    return {'id': id.toString(), 'name': name, 'icon': icon, 'color': color};
  }

  IconData getIconData() {
     
    if (RegExp(r'^\d+$').hasMatch(icon)) {
      return IconData(int.parse(icon), fontFamily: 'MaterialIcons');
    }

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
