import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/quick_add_labels.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  group('resolve', () {
    test('returns the leaf node with its own label and icon', () {
      final node = taxonomy.resolve('restauration.cafe');

      expect(node, isNotNull);
      expect(node!.slug, 'restauration.cafe');
      expect(node.label, 'Café');
      expect(node.icon, 'local_cafe');
    });

    test('exposes the parent group of a leaf', () {
      final node = taxonomy.resolve('restauration.cafe')!;

      expect(node.group.key, 'restauration');
      expect(node.group.label, 'Restauration');
      expect(node.group.icon, 'restaurant');
      expect(node.group.type, TransactionType.expense);
    });

    test('inherits the group color', () {
      final node = taxonomy.resolve('logement.loyer')!;

      expect(node.color, node.group.color);
      expect(node.color, 0xFF3F51B5);
    });

    test('resolves an income leaf', () {
      final node = taxonomy.resolve('salaire.salaire_net')!;

      expect(node.label, 'Salaire net');
      expect(node.group.type, TransactionType.income);
    });

    test('returns null for an unknown slug', () {
      expect(taxonomy.resolve('inconnu.autre'), isNull);
      expect(taxonomy.resolve('restauration.inconnu'), isNull);
    });

    test('returns null for a malformed slug', () {
      expect(taxonomy.resolve('restauration'), isNull);
      expect(taxonomy.resolve(''), isNull);
    });

    test('resolves every model label', () {
      for (final label in QuickAddLabels.categories) {
        expect(taxonomy.resolve(label), isNotNull, reason: label);
      }
    });
  });

  group('group', () {
    test('returns a group by key', () {
      expect(taxonomy.group('voyage')!.label, 'Voyages');
    });

    test('returns null for an unknown key', () {
      expect(taxonomy.group('inconnu'), isNull);
    });

    test('exposes its children in declaration order', () {
      final slugs = taxonomy.group('voyage')!.children.map((c) => c.slug);

      expect(slugs, [
        'voyage.transport_longue_distance',
        'voyage.hebergement',
        'voyage.location_vehicule',
        'voyage.activite_visite',
      ]);
    });

    test('every child points back to its group', () {
      for (final group in taxonomy.groups) {
        for (final child in group.children) {
          expect(child.group, same(group), reason: child.slug);
        }
      }
    });
  });

  group('groups', () {
    test('lists every group across both sections', () {
      expect(taxonomy.groups.length, 15);
    });

    test('filters by transaction type', () {
      expect(taxonomy.groupsOfType(TransactionType.expense).length, 11);
      expect(taxonomy.groupsOfType(TransactionType.income).length, 4);
    });

    test('leaves cover every model label', () {
      expect(
        taxonomy.leaves.map((leaf) => leaf.slug),
        QuickAddLabels.categories,
      );
    });
  });

  group('deprecation', () {
    test('none of the shipped nodes are deprecated', () {
      expect(taxonomy.leaves.where((leaf) => leaf.isDeprecated), isEmpty);
    });

    test('selectable leaves exclude deprecated ones', () {
      for (final group in taxonomy.groups) {
        expect(
          group.selectableChildren.every((child) => !child.isDeprecated),
          isTrue,
        );
      }
    });
  });

  group('load', () {
    test('is idempotent', () async {
      await taxonomy.load();
      expect(taxonomy.leaves.length, QuickAddLabels.categories.length);
    });
  });

  group('version guard', () {
    test('rejects a taxonomy built for another version', () {
      expect(
        () => CategoryTaxonomyService().loadFromJson({
          'version': CategoryTaxonomyService.expectedVersion + 1,
          'expenses': <String, dynamic>{},
          'income': <String, dynamic>{},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a group without subcategories', () {
      expect(
        () => CategoryTaxonomyService().loadFromJson({
          'version': CategoryTaxonomyService.expectedVersion,
          'expenses': {
            'vide': {
              'label': 'Vide',
              'icon': 'home',
              'color': '#000000',
              'subcategories': <String, dynamic>{},
            },
          },
          'income': <String, dynamic>{},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a node missing a required field', () {
      expect(
        () => CategoryTaxonomyService().loadFromJson({
          'version': CategoryTaxonomyService.expectedVersion,
          'expenses': {
            'logement': {
              'label': 'Logement',
              'icon': 'home',
              'color': '#3F51B5',
              'subcategories': {
                'loyer': {'icon': 'apartment'},
              },
            },
          },
          'income': <String, dynamic>{},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
