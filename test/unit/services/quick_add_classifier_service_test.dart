import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/constants/quick_add_labels.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_model_runner.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer.dart';

class MockTokenizer extends Mock implements QuickAddTokenizer {}

class MockModelRunner extends Mock implements QuickAddModelRunner {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTokenizer tokenizer;
  late MockModelRunner runner;
  late CategoryTaxonomyService taxonomy;
  late QuickAddClassifierService classifier;

  const emptyTokens = (inputIds: <int>[2, 1], attentionMask: <int>[1, 1]);

  QuickAddModelOutput outputFor({
    required int typeIndex,
    required String category,
    required int recurrenceIndex,
  }) {
    return (
      type: (index: typeIndex, confidence: 0.99),
      category: (
        index: QuickAddLabels.categories.indexOf(category),
        confidence: 0.95,
        topIndices: [
          QuickAddLabels.categories.indexOf(category),
          QuickAddLabels.categories.indexOf('restauration.bar'),
        ],
      ),
      recurrence: (index: recurrenceIndex, confidence: 0.9),
    );
  }

  setUpAll(() {
    registerFallbackValue(emptyTokens);
  });

  setUp(() async {
    tokenizer = MockTokenizer();
    runner = MockModelRunner();
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();

    when(() => tokenizer.encode(any())).thenReturn(emptyTokens);

    classifier = QuickAddClassifierService(
      tokenizer: tokenizer,
      modelRunner: runner,
      taxonomy: taxonomy,
    );
  });

  group('QuickAddClassifierService', () {
    test('leaves the amount null when the text carries none', () async {
      when(() => runner.run(any())).thenAnswer(
        (_) async => outputFor(
          typeIndex: 0,
          category: 'alimentation.supermarche',
          recurrenceIndex: 0,
        ),
      );

      final result = await classifier.classify('courses carrefour');

      expect(result.amount, isNull);
      expect(result.name, 'Courses carrefour');
      expect(result.categorySlug, 'alimentation.supermarche');
    });

    test('sends the raw text to the model when there is no amount', () async {
      when(() => runner.run(any())).thenAnswer(
        (_) async => outputFor(
          typeIndex: 0,
          category: 'alimentation.supermarche',
          recurrenceIndex: 0,
        ),
      );

      await classifier.classify('courses carrefour');

      verify(() => tokenizer.encode('courses carrefour')).called(1);
    });

    test('sends the canonical form to the model, keeps the typed name', () async {
      when(() => runner.run(any())).thenAnswer(
        (_) async => outputFor(
          typeIndex: 0,
          category: 'alimentation.supermarche',
          recurrenceIndex: 0,
        ),
      );

      final result = await classifier.classify('Père &Fils 20€');

      verify(() => tokenizer.encode('pere & fils')).called(1);
      expect(result.name, 'Père &Fils');
    });

    test('classifies a one-time expense', () async {
      when(() => runner.run(any())).thenAnswer(
        (_) async => outputFor(
          typeIndex: 0,
          category: 'restauration.restaurant',
          recurrenceIndex: 0,
        ),
      );

      final result = await classifier.classify('resto italien 25');

      expect(result.type, TransactionType.expense);
      expect(result.category.group.label, 'Restauration');
      expect(result.categorySlug, 'restauration.restaurant');
      expect(result.frequency, Frequency.oneTime);
      expect(result.amount, 25.0);
      expect(result.name, 'Resto italien');
    });

    test('classifies a recurring income', () async {
      when(() => runner.run(any())).thenAnswer(
        (_) async => outputFor(
          typeIndex: 1,
          category: 'salaire.salaire_net',
          recurrenceIndex: 1,
        ),
      );

      final result = await classifier.classify('salaire 2500');

      expect(result.type, TransactionType.income);
      expect(result.category.group.label, 'Salaire');
      expect(result.frequency, Frequency.monthly);
      expect(result.amount, 2500.0);
    });

    test('sends the cleaned text to the model', () async {
      when(() => runner.run(any())).thenAnswer(
        (_) async => outputFor(
          typeIndex: 0,
          category: 'loisirs.streaming',
          recurrenceIndex: 1,
        ),
      );

      await classifier.classify('netflix 13,99€');

      verify(() => tokenizer.encode('netflix')).called(1);
    });

    test(
      'falls back to the subcategory label when text is only an amount',
      () async {
        when(() => runner.run(any())).thenAnswer(
          (_) async => outputFor(
            typeIndex: 0,
            category: 'restauration.cafe',
            recurrenceIndex: 0,
          ),
        );

        final result = await classifier.classify('20€');

        expect(result.name, 'Café');
      },
    );

    test('exposes the runner-up categories as suggestions', () async {
      when(() => runner.run(any())).thenAnswer(
        (_) async => outputFor(
          typeIndex: 0,
          category: 'restauration.restaurant',
          recurrenceIndex: 0,
        ),
      );

      final result = await classifier.classify('resto 25');

      expect(result.categorySuggestions, [
        'restauration.restaurant',
        'restauration.bar',
      ]);
    });

    test('reports model confidences', () async {
      when(() => runner.run(any())).thenAnswer(
        (_) async => outputFor(
          typeIndex: 0,
          category: 'transport.essence',
          recurrenceIndex: 0,
        ),
      );

      final result = await classifier.classify('essence 60');

      expect(result.typeConfidence, 0.99);
      expect(result.categoryConfidence, 0.95);
      expect(result.recurrenceConfidence, 0.9);
    });
  });
}
