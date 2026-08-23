import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/data/legacy_category_mapper.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryTaxonomyService taxonomy;
  late LegacyCategoryMapper mapper;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    mapper = LegacyCategoryMapper(taxonomy);
  });

  group('categories shipped by default up to v0.7.5', () {
    const expected = {
      'Alimentation': 'alimentation.supermarche',
      'Logement': 'logement.loyer',
      'Transport': 'transport.essence',
      'Loisirs': 'loisirs.cinema_sortie',
      'Santé': 'sante_beaute.medecin',
      'Shopping': 'shopping.vetements',
      'Divers': 'divers.autre',
    };

    expected.forEach((name, slug) {
      test('maps "$name" to $slug', () {
        expect(mapper.expenseSlugFor(name), slug);
        expect(taxonomy.resolve(slug), isNotNull);
      });
    });

    test('maps the income default to the fallback', () {
      expect(mapper.expenseSlugFor('Salaire'), LegacyCategoryMapper.fallback);
    });
  });

  group('custom categories', () {
    test('matches a leaf label exactly', () {
      expect(mapper.expenseSlugFor('Animaux'), 'divers.animaux');
      expect(mapper.expenseSlugFor('Essence'), 'transport.essence');
    });

    test('ignores case, accents and surrounding spaces', () {
      expect(mapper.expenseSlugFor('  PHARMACIE '), 'sante_beaute.pharmacie');
      expect(mapper.expenseSlugFor('peage'), 'transport.peage');
      expect(mapper.expenseSlugFor('alimentation'), 'alimentation.supermarche');
    });

    test('falls back when the label belongs to an income group', () {
      expect(mapper.expenseSlugFor('Prime'), LegacyCategoryMapper.fallback);
    });

    test('falls back on an unknown name', () {
      expect(mapper.expenseSlugFor('Chats'), LegacyCategoryMapper.fallback);
      expect(mapper.expenseSlugFor(''), LegacyCategoryMapper.fallback);
    });

    test('the fallback itself is a valid taxonomy leaf', () {
      expect(taxonomy.resolve(LegacyCategoryMapper.fallback), isNotNull);
    });
  });
}
