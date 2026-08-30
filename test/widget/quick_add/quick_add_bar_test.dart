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
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_account_line.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';

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

    when(() => expenseRepository.getClosed()).thenReturn([]);
    when(() => expenseRepository.add(any())).thenReturn(7);
    when(() => expenseRepository.delete(any())).thenReturn(true);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getClosed()).thenReturn([]);
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

  Future<void> pumpBar(WidgetTester tester, {bool focused = true}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(expenseRepository),
          revenueRepositoryProvider.overrideWithValue(revenueRepository),
          accountProvider.overrideWith(
            () => FakeAccountNotifier([accountOf(1, 'Courant')]),
          ),
          categoryMemoryProvider.overrideWithValue(memory),
          categoryOverrideRepositoryProvider.overrideWithValue(overrides),
          quickAddClassifierProvider.overrideWith((ref) => classifier),
          categoryDisplayResolverProvider.overrideWith(
            (ref) async =>
                CategoryDisplayResolver(taxonomy: taxonomy, overrides: const {}),
          ),
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

  testWidgets('n\'offre pas de sortie sur un champ vide, meme vise', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.close_rounded), findsNothing);
  });

  testWidgets('offers a way out as soon as there is something to clear', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mc do');
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.close_rounded), findsOneWidget);
  });

  testWidgets('keeps the scan under the thumb at all times', (tester) async {
    await pumpBar(tester, focused: false);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.photo_camera_rounded), findsOneWidget);
  });

  testWidgets('the send button only ever sends, the scan keeps its own', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mc do 12');
    await tester.pump(
      QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.photo_camera_rounded), findsOneWidget);
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

  testWidgets('the keyboard send action keeps the rafale going too', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(TextField));
    await typeAndAnalyze(tester, 'mc do 12');

    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    verify(() => expenseRepository.add(any())).called(1);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '');
    expect(field.focusNode!.hasFocus, isTrue);

    await tester.pump(QuickAddRecentSubmissions.retention);
    await tester.pumpAndSettle();
  });

  Color glyphColor(WidgetTester tester, IconData icon) =>
      tester.widget<Icon>(find.byIcon(icon)).color!;

  BoxDecoration roundButtonSkin(WidgetTester tester, IconData icon) {
    final button = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.byIcon(icon),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    return button.decoration! as BoxDecoration;
  }

  testWidgets('l\'envoi vit dans le champ, pas a cote', (tester) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    expect(
      find.descendant(
        of: find.byType(FrostedTextField),
        matching: find.byIcon(Symbols.arrow_upward_rounded),
      ),
      findsOneWidget,
    );

    final field = tester.getRect(find.byType(FrostedTextField));
    final send = tester.getRect(find.byIcon(Symbols.arrow_upward_rounded));
    expect(field.contains(send.center), isTrue);
  });

  testWidgets('l\'envoi n\'apparait que quand il y a de quoi envoyer', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.arrow_upward_rounded), findsNothing);

    // Un texte sans montant n'est pas une transaction : rien à envoyer.
    when(() => classifier.classify(any())).thenAnswer((invocation) async {
      final input = invocation.positionalArguments.first as String;
      return QuickAddClassification(
        type: TransactionType.expense,
        category: taxonomy.resolve('restauration.fast_food')!,
        frequency: Frequency.oneTime,
        date: DateTime(2026, 8, 20),
        amount: input.contains(RegExp(r'\d')) ? 12.0 : null,
        name: 'Mc do',
        typeConfidence: 0.99,
        categoryConfidence: 0.9,
        recurrenceConfidence: 0.9,
        cleanedText: 'mc do',
      );
    });
    await typeAndAnalyze(tester, 'mc do');
    expect(find.byIcon(Symbols.arrow_upward_rounded), findsNothing);

    await typeAndAnalyze(tester, 'mc do 12');
    expect(find.byIcon(Symbols.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('l\'envoi garde sa couleur, de la fleche au check', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    final ready = glyphColor(tester, Symbols.arrow_upward_rounded);

    await tester.tap(find.byIcon(Symbols.arrow_upward_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(glyphColor(tester, Symbols.check_rounded), ready);

    await tester.pump(QuickAddBarState.sentFlash);
    await tester.pump(QuickAddRecentSubmissions.retention);
    await tester.pumpAndSettle();
  });

  testWidgets('l\'accent tient a l\'envoi, le scan reste le second geste', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    final scheme = AppTheme.light().colorScheme;

    expect(glyphColor(tester, Symbols.arrow_upward_rounded), scheme.primary);
    expect(
      roundButtonSkin(tester, Symbols.photo_camera_rounded).color,
      isNot(scheme.primary),
    );
  });

  testWidgets('la ligne de compte s\'aligne sur le champ, pas sur le scan', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    expect(
      tester.getTopLeft(find.byType(QuickAddAccountLine)).dx,
      tester.getTopLeft(find.byType(FrostedTextField)).dx,
    );
  });

  testWidgets('hands what it recorded to the journal', (tester) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();
    await typeAndAnalyze(tester, 'mc do 12');

    // The journal is what keeps the submission alive in the app ; here it
    // stands in for it.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(QuickAddBar)),
    );
    final subscription = container.listen(
      quickAddRecentSubmissionsProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await tester.tap(find.byIcon(Symbols.arrow_upward_rounded));
    await tester.pumpAndSettle();

    final submissions = container.read(quickAddRecentSubmissionsProvider);

    expect(submissions.single.id, 7);
    expect(submissions.single.name, 'Mc do');

    await tester.pump(QuickAddRecentSubmissions.retention);
    await tester.pumpAndSettle();
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

    // Le brouillon est reparti à vide : le bouton redevient le raccourci scan.
    expect(find.byIcon(Symbols.check_rounded), findsNothing);
    expect(find.byIcon(Symbols.photo_camera_rounded), findsOneWidget);

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

    await tester.showKeyboard(find.byType(TextField));
    await tester.tap(find.byIcon(Symbols.close_rounded));
    await tester.pumpAndSettle();

    expect(container.read(quickAddProvider).isEmpty, isTrue);

    // Vider le champ n'est pas en sortir : la frappe suivante part tout de
    // suite, sans re-viser le champ.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '');
    expect(field.focusNode!.hasFocus, isTrue);
  });
}
