import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockClassifierService extends Mock implements QuickAddClassifierService {}

class FakeCategoryModel extends Fake implements CategoryModel {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

class FakeRevenueModel extends Fake implements RevenueModel {}

const TaxonomyGroup restaurationGroup = (
  key: 'restauration',
  label: 'Restauration',
  icon: 'restaurant',
  color: 0xFFF44336,
  type: TransactionType.expense,
);

const TaxonomyGroup salaireGroup = (
  key: 'salaire',
  label: 'Salaire',
  icon: 'paid',
  color: 0xFF4CAF50,
  type: TransactionType.income,
);

QuickAddClassification expenseClassification({
  TaxonomyGroup group = restaurationGroup,
  double amount = 25.0,
  String name = 'Resto italien',
}) {
  return QuickAddClassification(
    type: TransactionType.expense,
    group: group,
    taxonomyCategory: '${group.key}.autre',
    frequency: Frequency.oneTime,
    amount: amount,
    name: name,
    typeConfidence: 0.99,
    categoryConfidence: 0.95,
    recurrenceConfidence: 0.9,
  );
}

QuickAddClassification incomeClassification() {
  return const QuickAddClassification(
    type: TransactionType.income,
    group: salaireGroup,
    taxonomyCategory: 'salaire.salaire_net',
    frequency: Frequency.monthly,
    amount: 2500.0,
    name: 'Salaire',
    typeConfidence: 0.99,
    categoryConfidence: 0.95,
    recurrenceConfidence: 0.9,
  );
}

void main() {
  late MockCategoryRepository categoryRepository;
  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockClassifierService classifier;

  setUpAll(() {
    registerFallbackValue(FakeCategoryModel());
    registerFallbackValue(FakeExpenseModel());
    registerFallbackValue(FakeRevenueModel());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'isCategoriesCreated': true});
    await PreferencesService.init();

    categoryRepository = MockCategoryRepository();
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    classifier = MockClassifierService();

    when(() => categoryRepository.getAll()).thenReturn([]);
    when(() => categoryRepository.add(any())).thenReturn(42);
    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => expenseRepository.add(any())).thenReturn(1);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.add(any())).thenReturn(1);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        revenueRepositoryProvider.overrideWithValue(revenueRepository),
        quickAddClassifierProvider.overrideWith((ref) => classifier),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('QuickAddNotifier.parse', () {
    test('maps classification to an existing category', () async {
      final existing = CategoryModel.create(
        name: 'restauration',
        icon: 'restaurant',
        color: 0xFFF44336,
      )..id = 7;
      when(() => categoryRepository.getAll()).thenReturn([existing]);
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => expenseClassification());

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('resto 25');

      final result = container.read(quickAddProvider).value;
      expect(result, isNotNull);
      expect(result!.type, TransactionType.expense);
      expect(result.categoryId, 7);
      expect(result.newCategory, isNull);
      expect(result.name, 'Resto italien');
      expect(result.amount, 25.0);
      expect(result.frequency, Frequency.oneTime.label);
    });

    test('proposes a new category when none matches', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => expenseClassification());

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('resto 25');

      final result = container.read(quickAddProvider).value;
      expect(result!.categoryId, isNull);
      expect(result.newCategory, 'Restauration');
      expect(result.newCategoryIcon, 'restaurant');
      expect(result.newCategoryColor, 0xFFF44336);
    });

    test('income result carries no category', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      await container.read(quickAddProvider.notifier).parse('salaire 2500');

      final result = container.read(quickAddProvider).value;
      expect(result!.type, TransactionType.income);
      expect(result.categoryId, isNull);
      expect(result.newCategory, isNull);
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
    test('adds an expense with the existing category', () async {
      final existing = CategoryModel.create(
        name: 'Restauration',
        icon: 'restaurant',
        color: 0xFFF44336,
      )..id = 7;
      when(() => categoryRepository.getAll()).thenReturn([existing]);
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
      expect(expense.categoryId, 7);
      expect(expense.accountId, 3);
      verifyNever(() => categoryRepository.add(any()));
      expect(container.read(quickAddProvider).value, isNull);
    });

    test('creates the category before adding the expense', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) async => expenseClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      await notifier.parse('resto 25');
      await notifier.confirm(3);

      final capturedCategory =
          verify(() => categoryRepository.add(captureAny())).captured;
      final category = capturedCategory.single as CategoryModel;
      expect(category.name, 'Restauration');
      expect(category.icon, 'restaurant');
      expect(category.color, 0xFFF44336);

      final capturedExpense =
          verify(() => expenseRepository.add(captureAny())).captured;
      final expense = capturedExpense.single as ExpenseModel;
      expect(expense.categoryId, 42);
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
