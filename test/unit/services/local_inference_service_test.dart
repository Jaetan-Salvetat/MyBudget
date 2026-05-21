import 'dart:convert';

import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/services/litert_engine_service.dart';
import 'package:mybudget/core/services/local_inference_service.dart';
import 'package:mybudget/models/category_model.dart';

class MockLitertEngineService extends Mock implements LitertEngineService {}

class MockLiteLmEngine extends Mock implements LiteLmEngine {}

class MockLiteLmConversation extends Mock implements LiteLmConversation {}

class FakeLiteLmConversationConfig extends Fake
    implements LiteLmConversationConfig {}

void main() {
  late MockLitertEngineService mockEngine;
  late MockLiteLmEngine mockLiteLmEngine;
  late MockLiteLmConversation mockConversation;
  late LocalInferenceService service;
  late List<CategoryModel> categories;

  setUpAll(() {
    registerFallbackValue(FakeLiteLmConversationConfig());
  });

  setUp(() {
    mockEngine = MockLitertEngineService();
    mockLiteLmEngine = MockLiteLmEngine();
    mockConversation = MockLiteLmConversation();

    when(() => mockEngine.engine).thenReturn(mockLiteLmEngine);
    when(() => mockLiteLmEngine.createConversation(any()))
        .thenAnswer((_) async => mockConversation);
    when(() => mockConversation.dispose()).thenAnswer((_) async {});

    service = LocalInferenceService(mockEngine);

    categories = [
      CategoryModel.create(
        name: 'Alimentation',
        icon: 'restaurant',
        color: 0xFFFF5722,
      ),
    ];
  });

  Map<String, dynamic> _validJson({
    String name = 'Café',
    double amount = 3.5,
    int? categoryId = 1,
    String frequency = 'Ponctuel',
  }) {
    return {
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'newCategory': null,
      'newCategoryIcon': null,
      'newCategoryColor': null,
      'frequency': frequency,
    };
  }

  group('LocalInferenceService', () {
    test('parses valid JSON response on first attempt', () async {
      final json = _validJson();
      when(() => mockConversation.sendMessage(any())).thenAnswer(
        (_) async => LiteLmMessage.model(jsonEncode(json)),
      );

      final result = await service.parseExpense('café 3.50', categories);

      expect(result.name, 'Café');
      expect(result.amount, 3.5);
      expect(result.categoryId, 1);
      expect(result.frequency, 'Ponctuel');
      verify(() => mockConversation.dispose()).called(1);
    });

    test('extracts JSON from surrounding text', () async {
      final json = _validJson(name: 'Loyer', amount: 800.0, frequency: 'Mensuel');
      final responseText = 'Voici le résultat :\n${jsonEncode(json)}\nBonne journée !';
      when(() => mockConversation.sendMessage(any())).thenAnswer(
        (_) async => LiteLmMessage.model(responseText),
      );

      final result = await service.parseExpense('loyer 800', categories);

      expect(result.name, 'Loyer');
      expect(result.amount, 800.0);
    });

    test('retries on invalid first response and succeeds', () async {
      final json = _validJson();
      var callCount = 0;

      when(() => mockConversation.sendMessage(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return LiteLmMessage.model('Je ne comprends pas');
        }
        return LiteLmMessage.model(jsonEncode(json));
      });

      final result = await service.parseExpense('café 3.50', categories);

      expect(result.name, 'Café');
      expect(callCount, 2);
    });

    test('throws QuickAddParseException when both attempts fail', () async {
      when(() => mockConversation.sendMessage(any())).thenAnswer(
        (_) async => LiteLmMessage.model('no json here'),
      );

      expect(
        () => service.parseExpense('café', categories),
        throwsA(isA<QuickAddParseException>()),
      );
    });

    test('rethrows QuickAddException subtypes', () async {
      when(() => mockConversation.sendMessage(any())).thenThrow(
        const QuickAddApiException(message: 'test'),
      );

      expect(
        () => service.parseExpense('café', categories),
        throwsA(isA<QuickAddApiException>()),
      );
    });

    test('wraps unexpected errors in QuickAddApiException', () async {
      when(() => mockConversation.sendMessage(any())).thenThrow(
        Exception('engine crash'),
      );

      expect(
        () => service.parseExpense('café', categories),
        throwsA(
          isA<QuickAddApiException>().having(
            (e) => e.message,
            'message',
            contains('IA locale'),
          ),
        ),
      );
    });

    test('disposes conversation even on error', () async {
      when(() => mockConversation.sendMessage(any())).thenThrow(
        Exception('boom'),
      );

      try {
        await service.parseExpense('café', categories);
      } catch (_) {}

      verify(() => mockConversation.dispose()).called(1);
    });

    test('parses response with new category fields', () async {
      final json = {
        'name': 'Cadeau maman',
        'amount': 20.0,
        'categoryId': null,
        'newCategory': 'Cadeaux',
        'newCategoryIcon': 'card_giftcard',
        'newCategoryColor': '#EC407A',
        'frequency': 'Ponctuel',
      };
      when(() => mockConversation.sendMessage(any())).thenAnswer(
        (_) async => LiteLmMessage.model(jsonEncode(json)),
      );

      final result = await service.parseExpense('cadeau maman 20€', categories);

      expect(result.categoryId, isNull);
      expect(result.newCategory, 'Cadeaux');
      expect(result.newCategoryIcon, 'card_giftcard');
      expect(result.newCategoryColor, '#EC407A');
    });
  });
}
