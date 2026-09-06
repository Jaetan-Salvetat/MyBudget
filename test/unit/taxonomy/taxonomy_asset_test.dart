import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/constants/quick_add_labels.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sections = ['expenses', 'income'];
  final slugPattern = RegExp(r'^[a-z0-9_]+$');

  late Map<String, dynamic> taxonomy;

  setUpAll(() {
    final raw = File(CategoryTaxonomyService.assetPath).readAsStringSync();
    taxonomy = json.decode(raw) as Map<String, dynamic>;
  });

  Iterable<MapEntry<String, dynamic>> groups() sync* {
    for (final section in sections) {
      yield* (taxonomy[section] as Map<String, dynamic>).entries;
    }
  }

  Iterable<MapEntry<String, Map<String, dynamic>>> subcategories() sync* {
    for (final group in groups()) {
      final children =
          (group.value as Map<String, dynamic>)['subcategories']
              as Map<String, dynamic>;
      for (final child in children.entries) {
        yield MapEntry(
          '${group.key}.${child.key}',
          child.value as Map<String, dynamic>,
        );
      }
    }
  }

  Iterable<String> orderedSlugs() => subcategories()
      .where((entry) => entry.value['deprecated'] != true)
      .map((entry) => entry.key);

  group('taxonomy asset', () {
    test('declares the version expected by the app', () {
      expect(taxonomy['version'], CategoryTaxonomyService.expectedVersion);
    });

    test('exposes both transaction sections', () {
      for (final section in sections) {
        expect(
          taxonomy[section],
          isA<Map<String, dynamic>>(),
          reason: 'Missing section "$section"',
        );
      }
    });

    test('every group key is a slug', () {
      for (final group in groups()) {
        expect(
          slugPattern.hasMatch(group.key),
          isTrue,
          reason: 'Invalid group slug "${group.key}"',
        );
      }
    });

    test('every group declares label, icon, color and subcategories', () {
      for (final group in groups()) {
        final value = group.value as Map<String, dynamic>;
        expect(value['label'], isA<String>(), reason: group.key);
        expect(value['icon'], isA<String>(), reason: group.key);
        expect(
          CategoryDefaults.hexToColor(value['color'] as String),
          isNotNull,
          reason: group.key,
        );
        expect(
          value['subcategories'],
          isA<Map<String, dynamic>>(),
          reason: group.key,
        );
        expect(
          value['subcategories'] as Map<String, dynamic>,
          isNotEmpty,
          reason: group.key,
        );
      }
    });

    test('every subcategory key is a slug and declares label and icon', () {
      for (final group in groups()) {
        final subcategories =
            (group.value as Map<String, dynamic>)['subcategories']
                as Map<String, dynamic>;
        for (final subcategory in subcategories.entries) {
          final slug = '${group.key}.${subcategory.key}';
          expect(
            slugPattern.hasMatch(subcategory.key),
            isTrue,
            reason: 'Invalid subcategory slug "$slug"',
          );
          final value = subcategory.value as Map<String, dynamic>;
          expect(value['label'], isA<String>(), reason: slug);
          expect(value['icon'], isA<String>(), reason: slug);
        }
      }
    });

    test('every icon resolves to a declared symbol', () {
      final declared = CategoryDefaults.icons;
      for (final group in groups()) {
        final value = group.value as Map<String, dynamic>;
        expect(declared, contains(value['icon']), reason: group.key);
        final subcategories = value['subcategories'] as Map<String, dynamic>;
        for (final subcategory in subcategories.entries) {
          expect(
            declared,
            contains((subcategory.value as Map<String, dynamic>)['icon']),
            reason: '${group.key}.${subcategory.key}',
          );
        }
      }
    });

    test('group slugs are unique across sections', () {
      final keys = groups().map((group) => group.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('deprecated subcategories alias a live slug', () {
      final live = orderedSlugs().toSet();
      for (final entry in subcategories()) {
        if (entry.value['deprecated'] != true) continue;
        final alias = entry.value['alias_of'];
        expect(alias, isA<String>(), reason: entry.key);
        expect(live, contains(alias), reason: entry.key);
      }
    });

    test('an aliased subcategory is deprecated', () {
      for (final entry in subcategories()) {
        if (entry.value['alias_of'] == null) continue;
        expect(entry.value['deprecated'], isTrue, reason: entry.key);
      }
    });

    test('model labels match every live taxonomy slug in order', () {
      expect(
        QuickAddLabels.categories,
        orderedSlugs().toList(),
        reason: 'La tête ONNX ne couvre que les slugs actifs',
      );
    });

    test('model labels leave every deprecated slug out', () {
      for (final entry in subcategories()) {
        if (entry.value['deprecated'] != true) continue;
        expect(QuickAddLabels.categories, isNot(contains(entry.key)));
      }
    });

    test('a deprecated label still lands on a live category', () async {
      final service = CategoryTaxonomyService();
      await service.load();

      for (final entry in subcategories()) {
        if (entry.value['deprecated'] != true) continue;
        expect(service.resolve(entry.key)?.slug, entry.value['alias_of']);
      }
    });
  });

  group('evaluation corpus', () {
    const corpusPath = 'ml/classifier/evaluation/data/quick_add.json';

    late List<dynamic> cases;

    setUpAll(() {
      final raw = File(corpusPath).readAsStringSync();
      cases = (json.decode(raw) as Map<String, dynamic>)['cases'] as List;
    });

    test('is not empty', () {
      expect(cases, isNotEmpty);
    });

    test('every case targets a known taxonomy slug', () {
      final slugs = orderedSlugs().toSet();
      for (final testCase in cases.cast<Map<String, dynamic>>()) {
        expect(
          slugs,
          contains(testCase['category']),
          reason: 'Unknown slug for input "${testCase['input']}"',
        );
      }
    });

    test('every case declares a known type and recurrence', () {
      for (final testCase in cases.cast<Map<String, dynamic>>()) {
        expect(
          QuickAddLabels.types,
          contains(testCase['type']),
          reason: testCase['input'] as String,
        );
        expect(
          QuickAddLabels.recurrences,
          contains(testCase['recurrence']),
          reason: testCase['input'] as String,
        );
      }
    });

    test('inputs are unique', () {
      final inputs = cases
          .cast<Map<String, dynamic>>()
          .map((c) => c['input'])
          .toList();
      expect(inputs.toSet().length, inputs.length);
    });
  });
}
