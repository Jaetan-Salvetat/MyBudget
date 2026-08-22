import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/models/category_override_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  CategoryDisplayResolver resolverWith(List<CategoryOverrideModel> overrides) {
    return CategoryDisplayResolver(
      taxonomy: taxonomy,
      overrides: {for (final o in overrides) o.slug: o},
    );
  }

  group('without overrides', () {
    late CategoryDisplayResolver resolver;

    setUp(() => resolver = resolverWith([]));

    test('renders the taxonomy values', () {
      final display = resolver.resolve('restauration.cafe')!;

      expect(display.label, 'Café');
      expect(display.icon, 'local_cafe');
      expect(display.color, 0xFFF44336);
      expect(display.groupKey, 'restauration');
      expect(display.groupLabel, 'Restauration');
      expect(display.type, TransactionType.expense);
      expect(display.isGroup, isFalse);
    });

    test('renders a group', () {
      final display = resolver.resolveGroup('voyage')!;

      expect(display.label, 'Voyages');
      expect(display.icon, 'flight_takeoff');
      expect(display.isGroup, isTrue);
    });

    test('resolves the group of a leaf slug', () {
      expect(
        resolver.resolveGroupOfSlug('voyage.hebergement')!.label,
        'Voyages',
      );
    });

    test('returns null for unknown slugs', () {
      expect(resolver.resolve('inconnu.autre'), isNull);
      expect(resolver.resolveGroup('inconnu'), isNull);
      expect(resolver.resolveGroupOfSlug('inconnu.autre'), isNull);
    });

    test('lists groups by type', () {
      expect(resolver.groupsOfType(TransactionType.expense).length, 11);
      expect(resolver.groupsOfType(TransactionType.income).length, 4);
    });

    test('lists the children of a group', () {
      expect(resolver.childrenOf('voyage').map((child) => child.label), [
        'Avion & train',
        'Hébergement',
        'Location de véhicule',
        'Activités & visites',
      ]);
    });

    test('returns no children for an unknown group', () {
      expect(resolver.childrenOf('inconnu'), isEmpty);
    });
  });

  group('with overrides', () {
    test('a leaf override wins on label and icon', () {
      final resolver = resolverWith([
        CategoryOverrideModel.create(
          slug: 'restauration.cafe',
          name: 'Bistrot',
          icon: 'local_bar',
        ),
      ]);

      final display = resolver.resolve('restauration.cafe')!;

      expect(display.label, 'Bistrot');
      expect(display.icon, 'local_bar');
    });

    test('a partial override falls back to the taxonomy field by field', () {
      final resolver = resolverWith([
        CategoryOverrideModel.create(
          slug: 'restauration.cafe',
          name: 'Bistrot',
        ),
      ]);

      final display = resolver.resolve('restauration.cafe')!;

      expect(display.label, 'Bistrot');
      expect(display.icon, 'local_cafe');
      expect(display.color, 0xFFF44336);
    });

    test('a group colour override cascades to its leaves', () {
      final resolver = resolverWith([
        CategoryOverrideModel.create(slug: 'restauration', color: 0xFF00FF00),
      ]);

      expect(resolver.resolve('restauration.cafe')!.color, 0xFF00FF00);
      expect(resolver.resolveGroup('restauration')!.color, 0xFF00FF00);
    });

    test('a leaf always follows its group colour', () {
      final resolver = resolverWith([
        CategoryOverrideModel.create(slug: 'restauration', color: 0xFF00FF00),
        CategoryOverrideModel.create(
          slug: 'restauration.cafe',
          color: 0xFF0000FF,
        ),
      ]);

      expect(resolver.resolve('restauration.cafe')!.color, 0xFF00FF00);
      expect(resolver.resolve('restauration.bar')!.color, 0xFF00FF00);
    });

    test('a group rename shows through on its leaves', () {
      final resolver = resolverWith([
        CategoryOverrideModel.create(slug: 'restauration', name: 'Sorties'),
      ]);

      final display = resolver.resolve('restauration.cafe')!;

      expect(display.groupLabel, 'Sorties');
      expect(display.label, 'Café');
    });

    test('an override on an unknown slug is ignored', () {
      final resolver = resolverWith([
        CategoryOverrideModel.create(slug: 'inconnu.autre', name: 'X'),
      ]);

      expect(resolver.resolve('inconnu.autre'), isNull);
      expect(resolver.resolve('restauration.cafe')!.label, 'Café');
    });
  });

  group('moved nodes', () {
    // Un noeud deplace garde son ancien slug (les transactions le referencent)
    // et pointe vers sa nouvelle destination via alias_of.
    late CategoryDisplayResolver resolver;

    setUp(() {
      final moved = CategoryTaxonomyService()
        ..loadFromJson({
          'version': CategoryTaxonomyService.expectedVersion,
          'expenses': {
            'logement': {
              'label': 'Logement',
              'icon': 'home',
              'color': '#3F51B5',
              'subcategories': {
                'loyer': {'label': 'Loyer', 'icon': 'apartment'},
                'assurance': {
                  'label': 'Assurance',
                  'icon': 'shield',
                  'deprecated': true,
                  'alias_of': 'finance.assurance_habitation',
                },
              },
            },
            'finance': {
              'label': 'Finance & Assurances',
              'icon': 'account_balance',
              'color': '#607D8B',
              'subcategories': {
                'assurance_habitation': {
                  'label': 'Assurance habitation',
                  'icon': 'shield',
                },
              },
            },
          },
          'income': <String, dynamic>{},
        });
      resolver = CategoryDisplayResolver(taxonomy: moved, overrides: const {});
    });

    test('an aliased slug resolves to its destination leaf', () {
      final display = resolver.resolve('logement.assurance')!;

      expect(display.slug, 'finance.assurance_habitation');
      expect(display.label, 'Assurance habitation');
    });

    test('groupKeyOf reports the destination group, not the slug prefix', () {
      expect(resolver.groupKeyOf('logement.assurance'), 'finance');
      expect('logement.assurance'.split('.').first, 'logement');
    });

    test('resolveGroupOfSlug follows the alias too', () {
      expect(
        resolver.resolveGroupOfSlug('logement.assurance')!.label,
        'Finance & Assurances',
      );
    });

    test(
      'deprecated leaves are hidden from the picker but stay resolvable',
      () {
        expect(resolver.childrenOf('logement').map((c) => c.slug), [
          'logement.loyer',
        ]);
        expect(resolver.resolve('logement.assurance'), isNotNull);
      },
    );

    test('groupKeyOf returns null for an unknown slug', () {
      expect(resolver.groupKeyOf('inconnu.autre'), isNull);
    });
  });

  group('uncategorized bucket', () {
    late CategoryDisplayResolver resolver;

    setUp(() => resolver = resolverWith([]));

    test('a null slug lands in the bucket', () {
      expect(
        resolver.groupKeyOrUncategorized(null),
        CategoryDisplayResolver.uncategorizedKey,
      );
    });

    test('an unknown slug lands in the bucket rather than vanishing', () {
      expect(
        resolver.groupKeyOrUncategorized('inconnu.autre'),
        CategoryDisplayResolver.uncategorizedKey,
      );
    });

    test('a known slug keeps its group', () {
      expect(
        resolver.groupKeyOrUncategorized('restauration.cafe'),
        'restauration',
      );
    });

    test('renders as a grey catch-all', () {
      final display = resolver.uncategorized(TransactionType.expense);

      expect(display.label, 'Non catégorisé');
      expect(display.color, CategoryDisplayResolver.uncategorizedColor);
      expect(display.isGroup, isTrue);
      expect(display.type, TransactionType.expense);
    });

    test('the bucket key is not a resolvable group', () {
      expect(
        resolver.resolveGroup(CategoryDisplayResolver.uncategorizedKey),
        isNull,
      );
    });
  });

  group('search', () {
    late CategoryDisplayResolver resolver;

    setUp(() => resolver = resolverWith([]));

    List<String> slugs(String query, TransactionType type) =>
        resolver.search(query, type).map((leaf) => leaf.slug).toList();

    test('returns nothing for a blank query', () {
      expect(resolver.search('', TransactionType.expense), isEmpty);
      expect(resolver.search('   ', TransactionType.expense), isEmpty);
    });

    test('matches a leaf label ignoring case and accents', () {
      expect(
        slugs('cafe', TransactionType.expense),
        contains('restauration.cafe'),
      );
      expect(
        slugs('CAFÉ', TransactionType.expense),
        contains('restauration.cafe'),
      );
      expect(
        slugs('péage', TransactionType.expense),
        contains('transport.peage'),
      );
    });

    test('matches every leaf of a group when the group label matches', () {
      expect(
        slugs('restauration', TransactionType.expense),
        containsAll(['restauration.restaurant', 'restauration.cafe']),
      );
    });

    test('filters by transaction type', () {
      expect(slugs('salaire', TransactionType.expense), isEmpty);
      expect(
        slugs('salaire', TransactionType.income),
        contains('salaire.salaire_net'),
      );
    });

    test('searches the customised label, not the taxonomy one', () {
      final customised = resolverWith([
        CategoryOverrideModel.create(
          slug: 'restauration.cafe',
          name: 'Bistrot',
        ),
      ]);

      expect(
        customised
            .search('bistrot', TransactionType.expense)
            .map((leaf) => leaf.slug),
        contains('restauration.cafe'),
      );
      expect(
        customised
            .search('café', TransactionType.expense)
            .map((leaf) => leaf.slug),
        isNot(contains('restauration.cafe')),
      );
    });

    test('only returns selectable leaves', () {
      for (final leaf in resolver.search('e', TransactionType.expense)) {
        expect(
          resolver.childrenOf(leaf.groupKey).map((child) => child.slug),
          contains(leaf.slug),
        );
      }
    });

    test('returns each leaf once', () {
      final results = slugs('a', TransactionType.expense);

      expect(results.toSet().length, results.length);
    });
  });
}
