import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/category_memory_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_draft_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockClassifierService extends Mock implements QuickAddClassifierService {}

class MockCategoryMemoryService extends Mock implements CategoryMemoryService {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

class FakeRevenueModel extends Fake implements RevenueModel {}

TaxonomyNode leafOf(
  TaxonomyGroup group,
  String key,
  String label,
  String icon,
) {
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

final TaxonomyNode restaurantLeaf = leafOf(
  restaurationGroup,
  'restaurant',
  'Restaurant',
  'dinner_dining',
);

final TaxonomyNode barLeaf = leafOf(
  restaurationGroup,
  'bar',
  'Bar & apéro',
  'local_bar',
);

final TaxonomyNode salaireNetLeaf = leafOf(
  salaireGroup,
  'salaire_net',
  'Salaire net',
  'payments',
);

final DateTime today = DateTime(2026, 8, 20);

QuickAddClassification expenseClassification({
  TaxonomyNode? category,
  double? amount = 25.0,
  String name = 'Resto italien',
  double categoryConfidence = 0.95,
  DateTime? date,
  bool hasWrittenDate = false,
}) {
  return QuickAddClassification(
    type: TransactionType.expense,
    category: category ?? restaurantLeaf,
    frequency: Frequency.oneTime,
    date: date ?? today,
    hasWrittenDate: hasWrittenDate,
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
    date: today,
    amount: 2500.0,
    name: 'Salaire',
    cleanedText: 'salaire',
    typeConfidence: 0.99,
    categoryConfidence: 0.95,
    recurrenceConfidence: 0.9,
  );
}

/// Long enough for the debounced analysis to have fired and settled.
Future<void> pumpAnalysis() {
  return Future<void>.delayed(
    QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 120),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockClassifierService classifier;
  late MockCategoryMemoryService memory;
  late MockCategoryOverrideRepository overrideRepository;

  setUpAll(() {
    registerFallbackValue(FakeExpenseModel());
    registerFallbackValue(FakeRevenueModel());
  });

  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    classifier = MockClassifierService();
    memory = MockCategoryMemoryService();
    overrideRepository = MockCategoryOverrideRepository();

    when(() => overrideRepository.getAll()).thenReturn({});

    when(() => memory.recall(any())).thenReturn(null);
    when(() => memory.remember(any(), any())).thenAnswer((_) {});
    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => expenseRepository.getClosed()).thenReturn([]);
    when(() => expenseRepository.add(any())).thenReturn(7);
    when(() => expenseRepository.delete(any())).thenReturn(true);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getClosed()).thenReturn([]);
    when(() => revenueRepository.add(any())).thenReturn(9);
    when(() => revenueRepository.delete(any())).thenReturn(true);
    when(
      () => classifier.classify(any()),
    ).thenAnswer((_) async => expenseClassification());
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        revenueRepositoryProvider.overrideWithValue(revenueRepository),
        categoryMemoryProvider.overrideWithValue(memory),
        quickAddClassifierProvider.overrideWith((ref) => classifier),
        categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        categoryOverrideRepositoryProvider.overrideWithValue(
          overrideRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    // The draft is auto-disposed: in the app a widget watches it, here the
    // subscription plays that role.
    container.listen(quickAddProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  group('QuickAddNotifier.onInputChanged', () {
    test('extracts the amount before the model has run', () {
      final container = makeContainer();
      container.read(quickAddProvider.notifier).onInputChanged('resto 25');

      final draft = container.read(quickAddProvider);
      expect(draft.amount, 25.0);
      expect(draft.isStale, isTrue);
      verifyNever(() => classifier.classify(any()));
    });

    test('fills the category once the analysis lands', () async {
      final container = makeContainer();
      container.read(quickAddProvider.notifier).onInputChanged('resto 25');
      await pumpAnalysis();

      final draft = container.read(quickAddProvider);
      expect(draft.categorySlug, 'restauration.restaurant');
      expect(draft.name, 'Resto italien');
      expect(draft.type, TransactionType.expense);
      expect(draft.frequency, Frequency.oneTime);
      expect(draft.isStale, isFalse);
      expect(draft.isSubmittable, isTrue);
    });

    test('runs the model once for a burst of keystrokes', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);

      notifier.onInputChanged('r');
      notifier.onInputChanged('re');
      notifier.onInputChanged('resto');
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();

      verify(() => classifier.classify('resto 25')).called(1);
    });

    test('keeps the known category while the next analysis runs', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);

      notifier.onInputChanged('resto 25');
      await pumpAnalysis();
      notifier.onInputChanged('resto 25,50');

      final draft = container.read(quickAddProvider);
      expect(draft.categorySlug, 'restauration.restaurant');
      expect(draft.amount, 25.5);
      expect(draft.isStale, isTrue);
    });

    test('drops an analysis the input has moved past', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);

      when(() => classifier.classify('resto 25')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return expenseClassification();
      });
      when(
        () => classifier.classify('salaire 2500'),
      ).thenAnswer((_) async => incomeClassification());

      notifier.onInputChanged('resto 25');
      await Future<void>.delayed(
        QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 20),
      );
      notifier.onInputChanged('salaire 2500');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final draft = container.read(quickAddProvider);
      expect(draft.categorySlug, 'salaire.salaire_net');
      expect(draft.type, TransactionType.income);
    });

    test('clears the draft when the input is emptied', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);

      notifier.onInputChanged('resto 25');
      await pumpAnalysis();
      notifier.onInputChanged('');

      expect(container.read(quickAddProvider).isEmpty, isTrue);
      expect(container.read(quickAddProvider).categorySlug, isNull);
    });

    test('leaves the draft incomplete while no amount is typed', () async {
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) async => expenseClassification(amount: null));

      final container = makeContainer();
      container.read(quickAddProvider.notifier).onInputChanged('resto');
      await pumpAnalysis();

      final draft = container.read(quickAddProvider);
      expect(draft.categorySlug, 'restauration.restaurant');
      expect(draft.amount, isNull);
      expect(draft.isSubmittable, isFalse);
    });

    test('a remembered category overrides the prediction', () async {
      when(() => memory.recall('Resto italien')).thenReturn('restauration.bar');
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) async => expenseClassification(categoryConfidence: 0.3));

      final container = makeContainer();
      container.read(quickAddProvider.notifier).onInputChanged('resto 25');
      await pumpAnalysis();

      final draft = container.read(quickAddProvider);
      expect(draft.categorySlug, 'restauration.bar');
      expect(draft.isCategoryUncertain, isFalse);
    });

    test('the memory leaves type and recurrence untouched', () async {
      when(() => memory.recall(any())).thenReturn('restauration.bar');
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      container.read(quickAddProvider.notifier).onInputChanged('salaire 2500');
      await pumpAnalysis();

      final draft = container.read(quickAddProvider);
      expect(draft.type, TransactionType.income);
      expect(draft.frequency, Frequency.monthly);
      expect(draft.categorySlug, 'restauration.bar');
    });

    test('surfaces a classification failure on the draft', () async {
      when(
        () => classifier.classify(any()),
      ).thenThrow(StateError('session closed'));

      final container = makeContainer();
      container.read(quickAddProvider.notifier).onInputChanged('resto 25');
      await pumpAnalysis();

      final draft = container.read(quickAddProvider);
      expect(draft.analysisError, isNotNull);
      expect(draft.isStale, isFalse);
      expect(draft.amount, 25.0);
    });
  });

  group('QuickAddNotifier reading that lags behind the input', () {
    test('a pick is ignored while the reading is stale', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);

      notifier.onInputChanged('resto 25');
      await pumpAnalysis();
      notifier.onInputChanged('resto 25 avec Paul');
      notifier.selectCategory('restauration.bar');

      verifyNever(() => memory.remember(any(), any()));
      expect(
        container.read(quickAddProvider).categorySlug,
        'restauration.restaurant',
      );
    });
  });

  group('QuickAddNotifier.submit', () {
    test('enregistre la catégorie que le modèle a lue', () async {
      when(
        () => classifier.classify('resto 25'),
      ).thenAnswer((_) async => expenseClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();

      await notifier.submit(3);

      final expense =
          verify(() => expenseRepository.add(captureAny())).captured.single
              as ExpenseModel;
      expect(expense.categorySlug, restaurantLeaf.slug);
    });
  });

  group('QuickAddNotifier.submit while the model is still reading', () {
    test('cuts the pause short rather than dropping the tap', () async {
      when(
        () => classifier.classify('salaire 2500'),
      ).thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('salaire 2500');

      final submission = await notifier.submit(3);

      expect(submission.type, TransactionType.income);
      expect(submission.amount, 2500.0);
      verify(() => classifier.classify('salaire 2500')).called(1);
    });

    test('never records the category of the previous input', () async {
      when(
        () => classifier.classify('resto 25'),
      ).thenAnswer((_) async => expenseClassification());
      when(
        () => classifier.classify('salaire 2500'),
      ).thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();
      notifier.onInputChanged('salaire 2500');

      final submission = await notifier.submit(3);

      expect(submission.type, TransactionType.income);
      verifyNever(() => expenseRepository.add(any()));
    });

    test('waits for an analysis already in flight', () async {
      when(() => classifier.classify('salaire 2500')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return incomeClassification();
      });

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('salaire 2500');
      await Future<void>.delayed(
        QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 20),
      );

      final submission = await notifier.submit(3);

      expect(submission.type, TransactionType.income);
      verify(() => classifier.classify('salaire 2500')).called(1);
    });
  });

  group('QuickAddNotifier.submit without a category', () {
    test('a failed analysis still records the amount', () async {
      when(
        () => classifier.classify(any()),
      ).thenThrow(StateError('session closed'));

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('truc 25');
      await pumpAnalysis();

      expect(container.read(quickAddProvider).isSubmittable, isTrue);
      await notifier.submit(3);

      final expense =
          verify(() => expenseRepository.add(captureAny())).captured.single
              as ExpenseModel;
      expect(expense.amount, 25.0);
      expect(expense.categorySlug, QuickAddDraft.uncategorizedSlug);
    });
  });

  group('QuickAddNotifier.selectCategory', () {
    test('records the pick in the memory and clears the doubt', () async {
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) async => expenseClassification(categoryConfidence: 0.3));

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();
      notifier.selectCategory('restauration.bar');

      verify(
        () => memory.remember('Resto italien', 'restauration.bar'),
      ).called(1);
      final draft = container.read(quickAddProvider);
      expect(draft.categorySlug, 'restauration.bar');
      expect(draft.isCategoryUncertain, isFalse);
    });

    test('an income category turns the draft into a revenue', () async {
      final container = makeContainer();
      await container.read(categoryDisplayResolverProvider.future);
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();

      notifier.selectCategory('salaire.prime');

      final draft = container.read(quickAddProvider);
      expect(draft.categorySlug, 'salaire.prime');
      expect(draft.type, TransactionType.income);
    });

    test('an expense category turns the draft back into an expense', () async {
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      await container.read(categoryDisplayResolverProvider.future);
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('salaire 2500');
      await pumpAnalysis();

      notifier.selectCategory('restauration.bar');

      final draft = container.read(quickAddProvider);
      expect(draft.type, TransactionType.expense);
    });

    test('a revenue is recorded when the pick changed the type', () async {
      final container = makeContainer();
      await container.read(categoryDisplayResolverProvider.future);
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();
      notifier.selectCategory('salaire.prime');

      await notifier.submit(3);

      final revenue =
          verify(() => revenueRepository.add(captureAny())).captured.single
              as RevenueModel;
      expect(revenue.categorySlug, 'salaire.prime');
      verifyNever(() => expenseRepository.add(any()));
    });
  });

  group('QuickAddNotifier.submit', () {
    test('creates the expense and returns what can be undone', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();

      final submission = await notifier.submit(3);

      final expense =
          verify(() => expenseRepository.add(captureAny())).captured.single
              as ExpenseModel;
      expect(expense.name, 'Resto italien');
      expect(expense.amount, 25.0);
      expect(expense.categorySlug, 'restauration.restaurant');
      expect(expense.accountId, 3);
      expect(submission.id, 7);
      expect(submission.type, TransactionType.expense);
      expect(submission.name, 'Resto italien');
      expect(container.read(quickAddProvider).isEmpty, isTrue);
    });

    test('creates a revenue for an income draft', () async {
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('salaire 2500');
      await pumpAnalysis();

      final submission = await notifier.submit(3);

      final revenue =
          verify(() => revenueRepository.add(captureAny())).captured.single
              as RevenueModel;
      expect(revenue.name, 'Salaire');
      expect(revenue.amount, 2500.0);
      expect(revenue.frequency, Frequency.monthly.label);
      expect(submission.id, 9);
      expect(submission.type, TransactionType.income);
      verifyNever(() => expenseRepository.add(any()));
    });

    test('refuses a draft without an amount', () async {
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) async => expenseClassification(amount: null));

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto');
      await pumpAnalysis();

      expect(
        () => notifier.submit(3),
        throwsA(isA<QuickAddNoAmountException>()),
      );
      verifyNever(() => expenseRepository.add(any()));
    });

    test('a pending analysis cannot resurrect a submitted draft', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();

      notifier.onInputChanged('resto 25 bis');
      await notifier.submit(3);
      await pumpAnalysis();

      expect(container.read(quickAddProvider), same(QuickAddDraft.empty));
    });
  });

  group('QuickAddNotifier date', () {
    test('records the day the text names', () async {
      when(() => classifier.classify(any())).thenAnswer(
        (_) async => expenseClassification(
          date: DateTime(2026, 8, 15),
          hasWrittenDate: true,
        ),
      );

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25 samedi');
      await pumpAnalysis();

      expect(container.read(quickAddProvider).date, DateTime(2026, 8, 15));
      await notifier.submit(3);

      final expense =
          verify(() => expenseRepository.add(captureAny())).captured.single
              as ExpenseModel;
      expect(expense.startDate, DateTime(2026, 8, 15));
    });

    test('une saisie du jour garde l\'heure où elle a été dite', () async {
      final today = DateTime.now();
      when(() => classifier.classify(any())).thenAnswer(
        (_) async => expenseClassification(
          date: DateTime(today.year, today.month, today.day),
          hasWrittenDate: true,
        ),
      );

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25 aujourd\'hui');
      await pumpAnalysis();

      final before = DateTime.now();
      await notifier.submit(3);

      final expense =
          verify(() => expenseRepository.add(captureAny())).captured.single
              as ExpenseModel;
      expect(expense.startDate.isBefore(before), isFalse);
    });

    test('a hand-picked day survives the next reading', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();

      notifier.selectDate(DateTime(2026, 8, 3));
      notifier.onInputChanged('resto 25 avec Paul');
      await pumpAnalysis();

      expect(container.read(quickAddProvider).date, DateTime(2026, 8, 3));
    });

    test('a hand-picked day is dropped with the draft', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();
      notifier.selectDate(DateTime(2026, 8, 3));

      await notifier.submit(3);
      notifier.onInputChanged('café 3');
      await pumpAnalysis();

      expect(container.read(quickAddProvider).date, today);
    });
  });

  group('QuickAddNotifier.undo', () {
    test('removes the expense that was just created', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('resto 25');
      await pumpAnalysis();

      await notifier.undo(await notifier.submit(3));

      verify(() => expenseRepository.delete(7)).called(1);
    });

    test('removes the revenue that was just created', () async {
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) async => incomeClassification());

      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);
      notifier.onInputChanged('salaire 2500');
      await pumpAnalysis();

      await notifier.undo(await notifier.submit(3));

      verify(() => revenueRepository.delete(9)).called(1);
      verifyNever(() => expenseRepository.delete(any()));
    });
  });

  group('QuickAddNotifier.reset', () {
    test('clears the draft and cancels the pending analysis', () async {
      final container = makeContainer();
      final notifier = container.read(quickAddProvider.notifier);

      notifier.onInputChanged('resto 25');
      notifier.reset();
      await pumpAnalysis();

      expect(container.read(quickAddProvider).isEmpty, isTrue);
      verifyNever(() => classifier.classify(any()));
    });
  });
}
