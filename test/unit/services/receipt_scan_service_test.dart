import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/receipt_scan_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<CategoryDisplay> categories;

  setUpAll(() async {
    final taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    final resolver = CategoryDisplayResolver(
      taxonomy: taxonomy,
      overrides: const {},
    );
    categories = resolver
        .groupsOfType(TransactionType.expense)
        .expand((group) => resolver.childrenOf(group.slug))
        .toList();
  });

  group('ReceiptScanService.fromStoredKey', () {
    late ApiKeyService keyService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      keyService = ApiKeyService();
    });

    test('rejects a scan while the user has not set a key', () {
      expect(
        () => ReceiptScanService.fromStoredKey(keyService),
        throwsA(isA<ScanMissingApiKeyException>()),
      );
    });

    test('builds a service from the key shared with quick add', () async {
      await keyService.save(AiProvider.gemini, 'user-key');

      expect(
        await ReceiptScanService.fromStoredKey(keyService),
        isA<ReceiptScanService>(),
      );
    });
  });

  group('ReceiptScanService.matchCategory', () {
    test('matches the qualified name sent in the prompt', () {
      expect(
        ReceiptScanService.matchCategory(
          'Alimentation > Supermarché',
          categories,
        ),
        'alimentation.supermarche',
      );
    });

    test('matches a bare leaf label', () {
      expect(
        ReceiptScanService.matchCategory('Supermarché', categories),
        'alimentation.supermarche',
      );
    });

    test('matches case-insensitively', () {
      expect(
        ReceiptScanService.matchCategory('sUpErMaRcHé', categories),
        'alimentation.supermarche',
      );
      expect(
        ReceiptScanService.matchCategory('alimentation > marché', categories),
        'alimentation.marche',
      );
    });

    test('returns null for an unknown label', () {
      expect(ReceiptScanService.matchCategory('Inconnu', categories), isNull);
      expect(
        ReceiptScanService.matchCategory('alimentation', categories),
        isNull,
      );
    });

    test('returns null for a null label', () {
      expect(ReceiptScanService.matchCategory(null, categories), isNull);
    });
  });

  group('ScannedItemModel', () {
    test('creates with all fields', () {
      const item = ScannedItemModel(
        name: 'Pâtes',
        amount: 2.30,
        categoryName: 'Supermarché',
        categorySlug: 'alimentation.supermarche',
      );

      expect(item.name, 'Pâtes');
      expect(item.amount, 2.30);
      expect(item.categoryName, 'Supermarché');
      expect(item.categorySlug, 'alimentation.supermarche');
    });

    test('creates with nullable fields', () {
      const item = ScannedItemModel(name: 'Article inconnu', amount: 5.00);

      expect(item.categoryName, isNull);
      expect(item.categorySlug, isNull);
    });

    test('copyWith updates amount', () {
      const item = ScannedItemModel(name: 'Test', amount: 10.0);
      final updated = item.copyWith(amount: 15.0);

      expect(updated.amount, 15.0);
      expect(updated.name, 'Test');
    });

    test('copyWith updates the category slug', () {
      const item = ScannedItemModel(name: 'Test', amount: 10.0);
      expect(item.categorySlug, isNull);

      final updated = item.copyWith(categorySlug: 'transport.essence');
      expect(updated.categorySlug, 'transport.essence');
    });
  });

  group('ReceiptScanResultModel', () {
    test('creates with all fields', () {
      final result = ReceiptScanResultModel(
        storeName: 'Carrefour',
        date: DateTime(2026, 4, 21),
        items: const [
          ScannedItemModel(
            name: 'Pâtes',
            amount: 2.30,
            categorySlug: 'alimentation.supermarche',
          ),
          ScannedItemModel(
            name: 'Essence',
            amount: 45.0,
            categorySlug: 'transport.essence',
          ),
        ],
      );

      expect(result.storeName, 'Carrefour');
      expect(result.date, DateTime(2026, 4, 21));
      expect(result.items.length, 2);
    });

    test('creates with nullable fields', () {
      final result = ReceiptScanResultModel(
        items: const [ScannedItemModel(name: 'Test', amount: 1.0)],
      );

      expect(result.storeName, isNull);
      expect(result.date, isNull);
    });

    test('copyWith updates date', () {
      final result = ReceiptScanResultModel(items: const []);
      expect(result.date, isNull);

      final updated = result.copyWith(date: DateTime(2026, 1, 1));
      expect(updated.date, DateTime(2026, 1, 1));
    });

    test('copyWith updates items', () {
      final result = ReceiptScanResultModel(
        items: const [
          ScannedItemModel(name: 'A', amount: 1.0),
          ScannedItemModel(name: 'B', amount: 2.0),
        ],
      );

      final updated = result.copyWith(items: [...result.items]..removeAt(0));

      expect(updated.items.length, 1);
      expect(updated.items.first.name, 'B');
    });
  });
}
