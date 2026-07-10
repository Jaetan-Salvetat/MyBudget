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

  group('CategoryTaxonomyService', () {
    test('resolves an expense subcategory to its group', () {
      final group = taxonomy.resolve('restauration.fast-food/friterie');

      expect(group, isNotNull);
      expect(group!.key, 'restauration');
      expect(group.label, 'Restauration');
      expect(group.icon, 'restaurant');
      expect(group.type, TransactionType.expense);
    });

    test('resolves an income subcategory to its group', () {
      final group = taxonomy.resolve('salaire.salaire net');

      expect(group!.key, 'salaire');
      expect(group.label, 'Salaire');
      expect(group.type, TransactionType.income);
    });

    test('parses group color from hex', () {
      final group = taxonomy.resolve('logement.loyer');

      expect(group!.color, 0xFF3F51B5);
    });

    test('returns null for unknown group', () {
      expect(taxonomy.resolve('inconnu.autre'), isNull);
    });

    test('resolves every model label to a group', () {
      for (final label in QuickAddLabels.categories) {
        expect(
          taxonomy.resolve(label),
          isNotNull,
          reason: 'No taxonomy group for "$label"',
        );
      }
    });
  });
}
