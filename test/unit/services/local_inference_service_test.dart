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
  late LocalInferenceService service;
  late List<CategoryModel> categories;

  setUpAll(() {
    registerFallbackValue(FakeLiteLmConversationConfig());
  });

  setUp(() {
    mockEngine = MockLitertEngineService();
    mockLiteLmEngine = MockLiteLmEngine();

    when(() => mockEngine.engine).thenReturn(mockLiteLmEngine);

    service = LocalInferenceService(mockEngine);

    categories = [
      CategoryModel.create(
        name: 'Alimentation',
        icon: 'restaurant',
        color: 0xFFFF5722,
      )..id = 1,
    ];
  });

  MockLiteLmConversation createMockConversation(
    List<String> responses,
  ) {
    final conversation = MockLiteLmConversation();
    var callIndex = 0;
    when(() => conversation.sendMessage(any())).thenAnswer((_) async {
      final text = responses[callIndex.clamp(0, responses.length - 1)];
      callIndex++;
      return LiteLmMessage.model(text);
    });
    when(() => conversation.dispose()).thenAnswer((_) async {});
    return conversation;
  }

  group('LocalInferenceService', () {
    test('parses existing category on first attempt', () async {
      final json = {
        'name': 'Café',
        'amount': 3.5,
        'frequency': 'Ponctuel',
        'categoryId': 1,
        'newCategory': null,
      };
      final conversation = createMockConversation([jsonEncode(json)]);
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async => conversation);

      final result = await service.parseExpense('café 3.50', categories);

      expect(result.name, 'Café');
      expect(result.amount, 3.5);
      expect(result.categoryId, 1);
      expect(result.newCategory, isNull);
      expect(result.newCategoryIcon, isNull);
      expect(result.newCategoryColor, isNull);
    });

    test('runs second request for icon/color when newCategory is set', () async {
      final parseJson = {
        'name': 'Salle de sport',
        'amount': 40.0,
        'frequency': 'Mensuel',
        'categoryId': null,
        'newCategory': 'Sport',
      };
      final categorizeJson = {
        'icon': 'fitness_center',
        'color': '#7E57C2',
      };

      final parseConversation = createMockConversation([jsonEncode(parseJson)]);
      final categorizeConversation =
          createMockConversation([jsonEncode(categorizeJson)]);

      var conversationIndex = 0;
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async {
        conversationIndex++;
        return conversationIndex == 1
            ? parseConversation
            : categorizeConversation;
      });

      final result = await service.parseExpense('sport 40/mois', categories);

      expect(result.name, 'Salle de sport');
      expect(result.newCategory, 'Sport');
      expect(result.newCategoryIcon, 'fitness_center');
      expect(result.newCategoryColor, '#7E57C2');
      expect(result.frequency, 'Mensuel');
    });

    test('uses fallback icon/color when categorize fails', () async {
      final parseJson = {
        'name': 'Cours',
        'amount': 30.0,
        'frequency': 'Mensuel',
        'categoryId': null,
        'newCategory': 'Éducation',
      };

      final parseConversation =
          createMockConversation([jsonEncode(parseJson)]);
      final categorizeConversation =
          createMockConversation(['not json at all']);

      var conversationIndex = 0;
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async {
        conversationIndex++;
        return conversationIndex == 1
            ? parseConversation
            : categorizeConversation;
      });

      final result = await service.parseExpense('cours 30/mois', categories);

      expect(result.newCategory, 'Éducation');
      expect(result.newCategoryIcon, 'label');
      expect(result.newCategoryColor, isNotNull);
    });

    test('extracts JSON from surrounding text', () async {
      final json = {
        'name': 'Loyer',
        'amount': 800.0,
        'frequency': 'Mensuel',
        'categoryId': null,
        'newCategory': 'Logement',
      };
      final responseText = 'Here is the result:\n${jsonEncode(json)}\nDone!';
      final categorizeJson = {'icon': 'home', 'color': '#42A5F5'};

      final parseConversation = createMockConversation([responseText]);
      final categorizeConversation =
          createMockConversation([jsonEncode(categorizeJson)]);

      var conversationIndex = 0;
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async {
        conversationIndex++;
        return conversationIndex == 1
            ? parseConversation
            : categorizeConversation;
      });

      final result = await service.parseExpense('loyer 800', categories);

      expect(result.name, 'Loyer');
      expect(result.amount, 800.0);
    });

    test('retries parse on invalid first response', () async {
      final json = {
        'name': 'Café',
        'amount': 3.5,
        'frequency': 'Ponctuel',
        'categoryId': 1,
        'newCategory': null,
      };
      final conversation = createMockConversation([
        'I cannot parse that',
        jsonEncode(json),
      ]);
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async => conversation);

      final result = await service.parseExpense('café 3.50', categories);

      expect(result.name, 'Café');
    });

    test('throws QuickAddParseException when both parse attempts fail',
        () async {
      final conversation = createMockConversation([
        'no json',
        'still no json',
      ]);
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async => conversation);

      expect(
        () => service.parseExpense('café', categories),
        throwsA(isA<QuickAddParseException>()),
      );
    });

    test('rethrows QuickAddException subtypes', () async {
      final conversation = MockLiteLmConversation();
      when(() => conversation.sendMessage(any())).thenThrow(
        const QuickAddApiException(message: 'test'),
      );
      when(() => conversation.dispose()).thenAnswer((_) async {});
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async => conversation);

      expect(
        () => service.parseExpense('café', categories),
        throwsA(isA<QuickAddApiException>()),
      );
    });

    test('wraps unexpected errors in QuickAddApiException', () async {
      final conversation = MockLiteLmConversation();
      when(() => conversation.sendMessage(any())).thenThrow(
        Exception('engine crash'),
      );
      when(() => conversation.dispose()).thenAnswer((_) async {});
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async => conversation);

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
      final conversation = MockLiteLmConversation();
      when(() => conversation.sendMessage(any())).thenThrow(
        Exception('boom'),
      );
      when(() => conversation.dispose()).thenAnswer((_) async {});
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async => conversation);

      try {
        await service.parseExpense('café', categories);
      } catch (_) {}

      verify(() => conversation.dispose()).called(1);
    });

    test('validates icon from categorize response', () async {
      final parseJson = {
        'name': 'Test',
        'amount': 10.0,
        'frequency': 'Ponctuel',
        'categoryId': null,
        'newCategory': 'Test',
      };
      final categorizeJson = {'icon': 'invalid_icon', 'color': '#EF5350'};

      final parseConversation =
          createMockConversation([jsonEncode(parseJson)]);
      final categorizeConversation =
          createMockConversation([jsonEncode(categorizeJson)]);

      var conversationIndex = 0;
      when(() => mockLiteLmEngine.createConversation(any()))
          .thenAnswer((_) async {
        conversationIndex++;
        return conversationIndex == 1
            ? parseConversation
            : categorizeConversation;
      });

      final result = await service.parseExpense('test 10', categories);

      expect(result.newCategoryIcon, 'label');
      expect(result.newCategoryColor, '#EF5350');
    });
  });
}
