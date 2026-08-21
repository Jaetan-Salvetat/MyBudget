import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';

void main() {
  group('CategoryDefaults', () {
    test('resolveIcon returns correct IconData for known keys', () {
      expect(CategoryDefaults.resolveIcon('restaurant'), Symbols.restaurant_rounded);
      expect(CategoryDefaults.resolveIcon('home'), Symbols.home_rounded);
      expect(CategoryDefaults.resolveIcon('local_cafe'), Symbols.local_cafe_rounded);
    });

    test('resolveIcon returns category icon for unknown keys', () {
      expect(CategoryDefaults.resolveIcon('nonexistent'), Symbols.category_rounded);
    });

    test('resolveIcon maps a known codePoint string to its declared icon', () {
      final codePoint = Symbols.restaurant_rounded.codePoint.toString();

      expect(CategoryDefaults.resolveIcon(codePoint), Symbols.restaurant_rounded);
    });

    test('resolveIcon returns category icon for an unknown codePoint string', () {
      final codePoint = Icons.star.codePoint.toString();

      expect(CategoryDefaults.resolveIcon(codePoint), Symbols.category_rounded);
    });

    test('colorToHex converts ARGB int to hex string', () {
      expect(CategoryDefaults.colorToHex(0xFFEF5350), '#EF5350');
      expect(CategoryDefaults.colorToHex(0xFF42A5F5), '#42A5F5');
      expect(CategoryDefaults.colorToHex(0xFF000000), '#000000');
    });

    test('hexToColor converts hex string to ARGB int', () {
      expect(CategoryDefaults.hexToColor('#EF5350'), 0xFFEF5350);
      expect(CategoryDefaults.hexToColor('#42A5F5'), 0xFF42A5F5);
      expect(CategoryDefaults.hexToColor('42A5F5'), 0xFF42A5F5);
    });

    test('hexToColor returns null for invalid hex', () {
      expect(CategoryDefaults.hexToColor('#ZZZZZZ'), isNull);
      expect(CategoryDefaults.hexToColor('not_hex'), isNull);
    });

    test('colorToHex and hexToColor are inverse operations', () {
      for (final color in CategoryDefaults.colors) {
        final hex = CategoryDefaults.colorToHex(color);
        final back = CategoryDefaults.hexToColor(hex);
        expect(back, color);
      }
    });

    test('icons map is not empty and contains expected keys', () {
      expect(CategoryDefaults.icons, isNotEmpty);
      expect(CategoryDefaults.icons.containsKey('restaurant'), isTrue);
      expect(CategoryDefaults.icons.containsKey('savings'), isTrue);
      expect(CategoryDefaults.icons.containsKey('card_giftcard'), isTrue);
    });

    test('colors list has at least 14 entries', () {
      expect(CategoryDefaults.colors.length, greaterThanOrEqualTo(14));
    });

    test('canonicalIconKey keeps a known key as is', () {
      expect(CategoryDefaults.canonicalIconKey('restaurant'), 'restaurant');
    });

    test('canonicalIconKey converts a codePoint string to its key', () {
      final codePoint = Symbols.savings_rounded.codePoint.toString();

      expect(CategoryDefaults.canonicalIconKey(codePoint), 'savings');
    });

    test('canonicalIconKey drops unknown keys and codePoints', () {
      expect(CategoryDefaults.canonicalIconKey('nonexistent'), isNull);
      expect(
        CategoryDefaults.canonicalIconKey(Icons.star.codePoint.toString()),
        isNull,
      );
      expect(CategoryDefaults.canonicalIconKey(null), isNull);
    });

    test('canonicalIconKey resolves to the same glyph it was given', () {
      for (final entry in CategoryDefaults.icons.entries) {
        final canonical =
            CategoryDefaults.canonicalIconKey(entry.value.codePoint.toString());

        expect(canonical, isNotNull);
        expect(CategoryDefaults.resolveIcon(canonical!), entry.value);
      }
    });
  });
}
