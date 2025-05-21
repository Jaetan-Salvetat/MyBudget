import 'package:flutter/material.dart';
import 'package:mybudget/data/models/category_model.dart';

extension CategoryModelExtensions on CategoryModel {
  static CategoryModel unknown() {
    return CategoryModel()
      ..name = 'Catégorie inconnue'
      ..icon = 'help_outline';
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
      case 'help_outline':
        return Icons.help_outline;
      case 'more_horiz':
      default:
        return Icons.more_horiz;
    }
  }
}
