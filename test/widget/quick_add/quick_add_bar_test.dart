import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:mybudget/core/services/category_memory_service.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';

class MockClassifierService extends Mock implements QuickAddClassifierService {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockCategoryMemoryService extends Mock implements CategoryMemoryService {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

class FakeRevenueModel extends Fake implements RevenueModel {}

class FakeAccountNotifier extends AccountNotifier {
  FakeAccountNotifier(this._accounts);

  final List<AccountModel> _accounts;

  @override
  Future<List<AccountModel>> build() async => _accounts;
}

AccountModel accountOf(int id, String name) {
  final account = AccountModel.create(name: name, bank: 'CM');
  account.id = id;
  return account;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClassifierService classifier;
  late MockCategoryMemoryService memory;
  late MockCategoryOverrideRepository overrides;
  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    registerFallbackValue(FakeExpenseModel());
    registerFallbackValue(FakeRevenueModel());
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() async {
    await initializeDateFormatting('fr_FR');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();

    classifier = MockClassifierService();
    memory = MockCategoryMemoryService();
    overrides = MockCategoryOverrideRepository();
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();

    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => expenseRepository.add(any())).thenReturn(7);
    when(() => expenseRepository.delete(any())).thenReturn(true);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => memory.recall(any())).thenReturn(null);
    when(() => memory.remember(any(), any())).thenAnswer((_) {});
    when(() => overrides.getAll()).thenReturn({});
    when(() => classifier.classify(any())).thenAnswer(
      (_) async => QuickAddClassification(
        type: TransactionType.expense,
        category: taxonomy.resolve('restauration.fast_food')!,
        frequency: Frequency.oneTime,
        date: DateTime(2026, 8, 20),
        amount: 12.0,
        name: 'Mc do',
        typeConfidence: 0.99,
        categoryConfidence: 0.9,
        recurrenceConfidence: 0.9,
        cleanedText: 'mc do',
      ),
    );
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    bool focused = true,
    bool scanAvailable = false,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(expenseRepository),
          revenueRepositoryProvider.overrideWithValue(revenueRepository),
          receiptScanAvailableProvider.overrideWithValue(scanAvailable),
          accountProvider.overrideWith(
            () => FakeAccountNotifier([accountOf(1, 'Courant')]),
          ),
          categoryMemoryProvider.overrideWithValue(memory),
          categoryOverrideRepositoryProvider.overrideWithValue(overrides),
          quickAddClassifierProvider.overrideWith((ref) => classifier),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: QuickAddBar(
              focused: focused,
              onFocusChanged: (_) {},
              onNoAccount: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offers no way out while there is nothing to leave', (
    tester,
  ) async {
    await pumpBar(tester, focused: false);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.close_rounded), findsNothing);
  });

  testWidgets('offers a way out as soon as the field is focused', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.close_rounded), findsOneWidget);
  });

  testWidgets('keeps the send button when no key can read a receipt', (
    tester,
  ) async {
    await pumpBar(tester, focused: false);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.photo_camera_rounded), findsNothing);
  });

  testWidgets('offers the scan while there is nothing to send', (tester) async {
    await pumpBar(tester, focused: false, scanAvailable: true);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.photo_camera_rounded), findsOneWidget);
  });

  testWidgets('gives the send button back as soon as a draft exists', (
    tester,
  ) async {
    await pumpBar(tester, scanAvailable: true);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mc do 12');
    await tester.pump(
      QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.photo_camera_rounded), findsNothing);
  });

  Future<void> typeAndAnalyze(WidgetTester tester, String input) async {
    await tester.enterText(find.byType(TextField), input);
    await tester.pump(
      QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('submitting keeps the keyboard up for the next entry', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    await tester.tap(find.byIcon(Symbols.arrow_upward_rounded));
    await tester.pumpAndSettle();

    verify(() => expenseRepository.add(any())).called(1);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '');
    expect(field.focusNode!.hasFocus, isTrue);

    await tester.pump(QuickAddRecentSubmissions.retention);
    await tester.pumpAndSettle();
  });

  testWidgets('what just landed stays on screen, undoable', (tester) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    await tester.tap(find.byIcon(Symbols.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mc do'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    verify(() => expenseRepository.delete(7)).called(1);
    expect(find.textContaining('Mc do'), findsNothing);
  });

  testWidgets('the line lets go on its own after the retention', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    await tester.tap(find.byIcon(Symbols.arrow_upward_rounded));
    await tester.pumpAndSettle();

    await tester.pump(QuickAddRecentSubmissions.retention);
    await tester.pumpAndSettle();

    expect(find.text('Annuler'), findsNothing);
    verifyNever(() => expenseRepository.delete(any()));
  });

  testWidgets('the send button flashes a check once it has sent', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    await tester.tap(find.byIcon(Symbols.arrow_upward_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Symbols.check_rounded), findsOneWidget);

    await tester.pump(QuickAddBarState.sentFlash);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.check_rounded), findsNothing);
    expect(find.byIcon(Symbols.arrow_upward_rounded), findsOneWidget);

    await tester.pump(QuickAddRecentSubmissions.retention);
    await tester.pumpAndSettle();
  });

  testWidgets('cancelling empties the field and the draft', (tester) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mc do 12');
    await tester.pump(
      QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(QuickAddBar)),
    );
    expect(container.read(quickAddProvider).amount, 12.0);

    await tester.tap(find.byIcon(Symbols.close_rounded));
    await tester.pumpAndSettle();

    expect(container.read(quickAddProvider).isEmpty, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
  });
}
