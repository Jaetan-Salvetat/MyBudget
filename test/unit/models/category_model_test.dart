import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/models/category_model.dart';

void main() {
  group('CategoryModel', () {
    test('getIconData should return correct icon for known strings', () {
      final cat = CategoryModel.create(name: 'Home', icon: 'home');
      expect(cat.getIconData(), Symbols.home_rounded);
    });

    test(
      'getIconData should fallback to category icon for unknown strings',
      () {
        final cat = CategoryModel.create(
          name: 'Unknown',
          icon: 'unknown_icon_xyz',
        );
        expect(cat.getIconData(), Symbols.category_rounded);
      },
    );

    test('getIconData should resolve a known codePoint string', () {
      final codePoint = Symbols.restaurant_rounded.codePoint;
      final cat = CategoryModel.create(name: 'Restaurant', icon: '$codePoint');

      expect(cat.getIconData(), Symbols.restaurant_rounded);
    });

    test('getIconData should fall back for an unknown codePoint string', () {
      final codePoint = Icons.star.codePoint;
      final cat = CategoryModel.create(name: 'Star', icon: '$codePoint');

      expect(cat.getIconData(), Symbols.category_rounded);
    });
  });
}
