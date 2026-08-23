import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/receipt_scan_service.dart';

/// Rejoue une réponse figée et retient ce qui est parti sur le réseau.
class _ScriptedChatClient implements AiChatClient {
  _ScriptedChatClient(this.response);

  final String response;
  String? prompt;
  AiImageAttachment? image;
  bool closed = false;

  @override
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  }) async {
    this.prompt = prompt;
    this.image = image;
    return response;
  }

  @override
  void close() => closed = true;
}

class _FailingChatClient implements AiChatClient {
  _FailingChatClient(this.failure);

  final AiRequestFailure failure;

  @override
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  }) async {
    throw AiRequestException(failure);
  }

  @override
  void close() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<CategoryDisplay> categories;

  final image = AiImageAttachment.jpeg(Uint8List.fromList([1, 2, 3]));

  String receipt({
    String? storeName = 'Carrefour',
    String? date = '2026-08-01',
    List<Map<String, dynamic>> items = const [
      {
        'name': 'Pain',
        'amount': 2.5,
        'discount': 0.0,
        'category': 'Alimentation > Supermarché',
      },
    ],
  }) {
    return jsonEncode({
      'store_name': storeName,
      'date': date,
      'items': items,
    });
  }

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

  group('ReceiptScanService.extractItems', () {
    test('reads a well-formed answer', () async {
      final client = _ScriptedChatClient(receipt());

      final result = await ReceiptScanService(
        client: client,
      ).extractItems(image, categories);

      expect(result.storeName, 'Carrefour');
      expect(result.date, DateTime(2026, 8, 1));
      expect(result.items.single.name, 'Pain');
      expect(result.items.single.amount, 2.5);
      expect(result.items.single.categorySlug, 'alimentation.supermarche');
    });

    test('sends the picture along with the prompt', () async {
      final client = _ScriptedChatClient(receipt());

      await ReceiptScanService(client: client).extractItems(image, categories);

      expect(client.image, same(image));
      expect(client.prompt, contains('Alimentation > Supermarché'));
    });

    test('keeps an item the model could not categorise', () async {
      final client = _ScriptedChatClient(
        receipt(
          items: const [
            {
              'name': 'Article inconnu',
              'amount': 4.0,
              'discount': 0.0,
              'category': 'Catégorie inventée',
            },
          ],
        ),
      );

      final result = await ReceiptScanService(
        client: client,
      ).extractItems(image, categories);

      expect(result.items.single.categorySlug, isNull);
      expect(result.items.single.categoryName, 'Catégorie inventée');
    });

    test('reads a discount as a deduction on the item', () async {
      final client = _ScriptedChatClient(
        receipt(
          items: const [
            {
              'name': 'Café',
              'amount': 5.0,
              'discount': 1.5,
              'category': 'Alimentation > Supermarché',
            },
          ],
        ),
      );

      final result = await ReceiptScanService(
        client: client,
      ).extractItems(image, categories);

      expect(result.items.single.effectiveAmount, 3.5);
    });

    test('accepts a receipt whose header is unreadable', () async {
      final client = _ScriptedChatClient(receipt(storeName: null, date: null));

      final result = await ReceiptScanService(
        client: client,
      ).extractItems(image, categories);

      expect(result.storeName, isNull);
      expect(result.date, isNull);
    });

    test('turns a provider failure into a scan failure', () async {
      final service = ReceiptScanService(
        client: _FailingChatClient(AiRequestFailure.quotaExceeded),
      );

      await expectLater(
        service.extractItems(image, categories),
        throwsA(isA<AiRequestException>()),
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

    test('ignores the case the model used', () {
      expect(
        ReceiptScanService.matchCategory('supermarché', categories),
        'alimentation.supermarche',
      );
    });

    test('returns null on a label outside the taxonomy', () {
      expect(
        ReceiptScanService.matchCategory('Catégorie inventée', categories),
        isNull,
      );
    });

    test('returns null when the model gave no category', () {
      expect(ReceiptScanService.matchCategory(null, categories), isNull);
    });
  });
}
