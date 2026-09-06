import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/data/model/category_override_model.dart';

void main() {
  group('CategoryOverrideModel', () {
    test('is empty when no field is customised', () {
      expect(
        CategoryOverrideModel.create(slug: 'restauration.cafe').isEmpty,
        isTrue,
      );
    });

    test('is not empty as soon as one field is set', () {
      for (final override in [
        CategoryOverrideModel.create(slug: 'a.b', name: 'Bistrot'),
        CategoryOverrideModel.create(slug: 'a.b', icon: 'local_bar'),
        CategoryOverrideModel.create(slug: 'a.b', color: 0xFF000000),
      ]) {
        expect(override.isEmpty, isFalse);
      }
    });

    test('treats a blank name as not customised', () {
      expect(
        CategoryOverrideModel.create(slug: 'a.b', name: '   ').isEmpty,
        isTrue,
      );
    });

    test('round-trips through json', () {
      final override = CategoryOverrideModel.create(
        slug: 'restauration.cafe',
        name: 'Bistrot',
        icon: 'local_bar',
        color: 0xFF112233,
      );

      final restored = CategoryOverrideModel.fromJson(override.toJson());

      expect(restored.slug, 'restauration.cafe');
      expect(restored.name, 'Bistrot');
      expect(restored.icon, 'local_bar');
      expect(restored.color, 0xFF112233);
    });

    test('keeps null fields null through json', () {
      final restored = CategoryOverrideModel.fromJson(
        CategoryOverrideModel.create(slug: 'a.b', name: 'X').toJson(),
      );

      expect(restored.name, 'X');
      expect(restored.icon, isNull);
      expect(restored.color, isNull);
    });

    test('canonicalises a legacy codePoint icon on creation', () {
      final override = CategoryOverrideModel.create(
        slug: 'a.b',
        icon: Symbols.local_bar_rounded.codePoint.toString(),
      );

      expect(override.icon, 'local_bar');
    });

    test('canonicalises a legacy codePoint icon coming from json', () {
      final restored = CategoryOverrideModel.fromJson({
        'slug': 'a.b',
        'icon': Symbols.local_bar_rounded.codePoint.toString(),
      });

      expect(restored.icon, 'local_bar');
    });

    test('drops an unknown icon rather than storing it', () {
      expect(
        CategoryOverrideModel.create(slug: 'a.b', icon: 'nope').icon,
        isNull,
      );
      expect(
        CategoryOverrideModel.create(slug: 'a.b', icon: 'nope').isEmpty,
        isTrue,
      );
    });
  });
}
