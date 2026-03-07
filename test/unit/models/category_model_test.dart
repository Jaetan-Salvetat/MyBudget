import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/category_model.dart';

void main() {
  group('CategoryModel', () {
    test('getIconData should return correct icon for known strings', () {
      final cat = CategoryModel.create(name: 'Home', icon: 'home');
      expect(cat.getIconData(), Icons.home);
    });

    test(
      'getIconData should fallback to category icon for unknown strings',
      () {
        final cat = CategoryModel.create(
          name: 'Unknown',
          icon: 'unknown_icon_xyz',
        );
        expect(cat.getIconData(), Icons.category);
      },
    );

    test('getIconData should handle integer strings (CodePoints)', () {
      final codePoint = Icons.star.codePoint;
      final cat = CategoryModel.create(name: 'Star', icon: '$codePoint');

      expect(cat.getIconData().codePoint, codePoint);
    });
  });
}
