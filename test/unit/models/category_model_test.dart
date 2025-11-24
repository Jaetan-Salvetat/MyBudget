import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/category_model.dart';

void main() {
  group('CategoryModel', () {
    test('should create a valid instance', () {
      final category = CategoryModel.create(
        name: 'Food',
        icon: 'restaurant',
        color: 0xFF000000,
      );

      expect(category.name, 'Food');
      expect(category.icon, 'restaurant');
      expect(category.color, 0xFF000000);
    });

    test('copyWith should return a new instance with updated values', () {
      final category = CategoryModel.create(
        name: 'Original',
        icon: 'icon',
        color: 0xFF000000,
      );

      final updated = category.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.icon, 'icon');
    });

    test('toJson should return correct map', () {
      final category = CategoryModel.create(
        name: 'Json Test',
        icon: 'icon',
        color: 0xFF000000,
      )..id = 5;

      final json = category.toJson();

      expect(json['id'], '5');
      expect(json['name'], 'Json Test');
      expect(json['icon'], 'icon');
      expect(json['color'], 0xFF000000);
    });

    test('fromJson should create correct instance', () {
      final json = {
        'id': '5',
        'name': 'Json Test',
        'icon': 'icon',
        'color': 0xFF000000,
      };

      final category = CategoryModel.fromJson(json);

      expect(category.id, 5);
      expect(category.name, 'Json Test');
      expect(category.icon, 'icon');
      expect(category.color, 0xFF000000);
    });

    test('getIconData should return correct IconData', () {
      final category = CategoryModel.create(name: 'Test', icon: 'restaurant');
      expect(category.getIconData(), Icons.restaurant);

      final categoryCodePoint = CategoryModel.create(
        name: 'Test',
        icon: Icons.home.codePoint.toString(),
      );
      expect(categoryCodePoint.getIconData().codePoint, Icons.home.codePoint);
    });
  });
}
