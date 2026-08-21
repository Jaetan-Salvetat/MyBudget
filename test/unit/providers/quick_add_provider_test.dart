import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/category_memory_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockClassifierService extends Mock implements QuickAddClassifierService {}

class MockCategoryMemoryService extends Mock implements CategoryMemoryService {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

class FakeRevenueModel extends Fake implements RevenueModel {}

TaxonomyNode leafOf(TaxonomyGroup group, String key, String label, String icon) {
  final node = TaxonomyNode(
    slug: '${group.key}.$key',
    label: label,
    icon: icon,
    group: group,
    isDeprecated: false,
    aliasOf: null,
  );
  group.children.add(node);
  return node;
}

final TaxonomyGroup restaurationGroup = TaxonomyGroup(
  key: 'restauration',
  label: 'Restauration',
  icon: 'restaurant',
  color: 0xFFF44336,
  type: TransactionType.expense,
);

final TaxonomyGroup salaireGroup = TaxonomyGroup(
  key: 'salaire',
  label: 'Salaire',
  icon: 'paid',
  color: 0xFF4CAF50,
  type: TransactionType.income,
);

final TaxonomyNode restaurantLeaf =
    leafOf(restaurationGroup, 'restaurant', 'Restaurant', 'dinner_dining');

final TaxonomyNode barLeaf =
    leafOf(restaurationGroup, 'bar', 'Bar & apéro', 'local_bar');

final TaxonomyNode salaireNetLeaf =
    leafOf(salaireGroup, 'salaire_net', 'Salaire net', 'payments');

QuickAddClassification expenseClassification({
  TaxonomyNode? category,
  double amount = 25.0,
  String name = 'Resto italien',
  double categoryConfidence = 0.95,
}) {
  return QuickAddClassification(
    type: TransactionType.expense,
    category: category ?? restaurantLeaf,
    frequency: Frequency.oneTime,
    amount: amount,
    name: name,
    typeConfidence: 0.99,
    categoryConfidence: categoryConfidence,
    recurrenceConfidence: 0.9,
    categorySuggestions: [restaurantLeaf.slug, barLeaf.slug],
    cleanedText: name,
  );
}

QuickAddClassification incomeClassification() {
  return QuickAddClassification(
    type: TransactionType.income,
    category: salaireNetLeaf,
    frequency: Frequency.monthly,
    amount: 2500.0,
    name: 'Salaire',
    cleanedText: 'salaire',
    typeConfidence: 0.99,
    categoryConfidence: 0.95,
    recurrenceConfidence: 0.9,
  );
}

void main() {
  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockClassifierService classifier;
  late MockCategoryMemoryService memory;

  setUpAll(() {
        registerFallbackValue(FakeExpenseModel());
    registerFallbackValue(FakeRevenueModel());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    classifier = MockClassifierService();
    memory = MockCategoryMemoryService();

    when(() => memory.recall(any())).thenReturn(null);
    when(() => memory.remember(any(), any())).thenAnswer((_) {});
    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => expenseRepository.add(any())).thenReturn(1);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.add(any())).thenReturn(1);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        revenueRepositoryProvider.overrideWithValue(revenueRepository),
        categoryMemoryProvider.overrideWithValue(memory),
        quickAddClassifierProvider.overrideWith((ref) => classifier),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('QuickAddNotifier.parse', () {
    test('carries the predicted leaf slug', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => expenseClassification());

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('resto 25');

      final result = container.read(quickAddProvider).value;
      expect(result, isNotNull);
      expect(result!.type, TransactionType.expense);
      expect(result.categorySlug, 'restauration.restaurant');
      expect(result.name, 'Resto italien');
      expect(result.amount, 25.0);
      expect(result.frequency, Frequency.oneTime.label);
    });

    test('flags a low-confidence category for confirmation', () async {
      when(() => classifier.classify(any())).thenAnswer(
        (_) async => expenseClassification(categoryConfidence: 0.3),
      );

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('truc 25');

      final result = container.read(quickAddProvider).value!;
      expect(result.needsCategoryConfirmation, isTrue);
      expect(result.categorySuggestions,
          ['restauration.restaurant', 'restauration.bar']);
    });

    test('a remembered category overrides the prediction', () async {
      when(() => memory.recall('Resto italien'))
          .thenReturn('loisirs.cinema_sortie');
      when(() => classifier.classify(any())).thenAnswer(
        (_) async => expenseClassification(categoryConfidence: 0.3),
      );

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('resto 25');

      final result = container.read(quickAddProvider).value!;
      expect(result.categorySlug, 'loisirs.cinema_sortie');
      expect(result.needsCategoryConfirmation, isFalse);
    });

    test('the memory leaves type and recurrence untouched', () async {
      when(() => memory.recall(any())).thenReturn('loisirs.cinema_sortie');
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('salaire 2500');

      final result = container.read(quickAddProvider).value!;
      expect(result.type, TransactionType.income);
      expect(result.frequency, Frequency.monthly.label);
      expect(result.categorySlug, 'loisirs.cinema_sortie');
    });

    test('selectCategory records the pick in the memory', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => expenseClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      await notifier.parse('resto 25');
      notifier.selectCategory('restauration.bar');

      verify(() => memory.remember('Resto italien', 'restauration.bar'))
          .called(1);
    });

    test('selectCategory overrides the prediction and clears the flag',
        () async {
      when(() => classifier.classify(any())).thenAnswer(
        (_) async => expenseClassification(categoryConfidence: 0.3),
      );

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      await notifier.parse('truc 25');
      notifier.selectCategory('restauration.bar');

      final result = container.read(quickAddProvider).value!;
      expect(result.categorySlug, 'restauration.bar');
      expect(result.needsCategoryConfirmation, isFalse);
    });

    test('income results carry their income slug', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('salaire 2500');

      final result = container.read(quickAddProvider).value;
      expect(result!.type, TransactionType.income);
      expect(result.categorySlug, 'salaire.salaire_net');
      expect(result.frequency, Frequency.monthly.label);
    });

    test('exposes QuickAddException as error state', () async {
      when(() => classifier.classify(any()))
          .thenThrow(const QuickAddNoAmountException());

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('carrefour');

      final state = container.read(quickAddProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<QuickAddNoAmountException>());
    });

    test('wraps unexpected errors in QuickAddClassificationException',
        () async {
      when(() => classifier.classify(any()))
          .thenThrow(StateError('session closed'));

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('resto 25');

      final state = container.read(quickAddProvider);
      expect(state.error, isA<QuickAddClassificationException>());
    });
  });

  group('QuickAddNotifier.confirm', () {
    test('adds an expense carrying the leaf slug', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => expenseClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      await notifier.parse('resto 25');
      await notifier.confirm(3);

      final captured =
          verify(() => expenseRepository.add(captureAny())).captured;
      final expense = captured.single as ExpenseModel;
      expect(expense.name, 'Resto italien');
      expect(expense.amount, 25.0);
      expect(expense.categorySlug, 'restauration.restaurant');
      expect(expense.accountId, 3);
      expect(container.read(quickAddProvider).value, isNull);
    });

    test('adds a revenue for an income result', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      await notifier.parse('salaire 2500');
      await notifier.confirm(3);

      final captured =
          verify(() => revenueRepository.add(captureAny())).captured;
      final revenue = captured.single as RevenueModel;
      expect(revenue.name, 'Salaire');
      expect(revenue.categorySlug, 'salaire.salaire_net');
      expect(revenue.amount, 2500.0);
      expect(revenue.accountId, 3);
      expect(revenue.frequency, Frequency.monthly.label);
      verifyNever(() => expenseRepository.add(any()));
      expect(container.read(quickAddProvider).value, isNull);
    });

    test('does nothing without a pending result', () async {
      final container = makeContainer();
      await container.read(quickAddProvider.notifier).confirm(3);

      verifyNever(() => expenseRepository.add(any()));
      verifyNever(() => revenueRepository.add(any()));
    });
  });

  group('QuickAddNotifier.reset', () {
    test('clears the pending result', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => expenseClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      await notifier.parse('resto 25');
      expect(container.read(quickAddProvider).value, isNotNull);

      notifier.reset();
      expect(container.read(quickAddProvider).value, isNull);
    });
  });
}
