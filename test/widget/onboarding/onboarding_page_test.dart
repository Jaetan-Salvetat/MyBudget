import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/onboarding/onboarding_page.dart';
import 'package:mybudget/ui/onboarding/widgets/account_setup_slide.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockTransferRepository extends Mock implements TransferRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class _FakeAccount extends Fake implements AccountModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAccountRepository accountRepository;
  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockLoanRepository loanRepository;
  late MockLoanEventRepository loanEventRepository;
  late MockTransferRepository transferRepository;
  late MockCategoryOverrideRepository overrideRepository;
  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    registerFallbackValue(_FakeAccount());
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    await initializeDateFormatting('fr_FR', null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();

    accountRepository = MockAccountRepository();
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    loanRepository = MockLoanRepository();
    loanEventRepository = MockLoanEventRepository();
    transferRepository = MockTransferRepository();
    overrideRepository = MockCategoryOverrideRepository();

    when(() => accountRepository.getAll()).thenReturn([]);
    when(() => accountRepository.add(any())).thenReturn(1);
    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => loanRepository.getAll()).thenReturn([]);
    when(() => loanEventRepository.getAll()).thenReturn([]);
    when(() => transferRepository.getActive()).thenReturn([]);
    when(() => overrideRepository.getAll()).thenReturn({});
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(accountRepository),
          expenseRepositoryProvider.overrideWithValue(expenseRepository),
          revenueRepositoryProvider.overrideWithValue(revenueRepository),
          loanRepositoryProvider.overrideWithValue(loanRepository),
          loanEventRepositoryProvider.overrideWithValue(loanEventRepository),
          transferRepositoryProvider.overrideWithValue(transferRepository),
          categoryOverrideRepositoryProvider.overrideWithValue(
            overrideRepository,
          ),
          categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingPage(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FrostedButton primaryButton(WidgetTester tester, String label) =>
      tester.widget<FrostedButton>(
        find.widgetWithText(FrostedButton, label),
      );

  testWidgets('ouvre sur la démonstration de saisie', (tester) async {
    await pumpOnboarding(tester);

    expect(find.text('Dis-le comme\nça te vient.'), findsOneWidget);
    expect(
      tester.widget<FrostedPageIndicator>(find.byType(FrostedPageIndicator)),
      isA<FrostedPageIndicator>()
          .having((i) => i.count, 'count', OnboardingPage.slideCount)
          .having((i) => i.currentIndex, 'currentIndex', 0),
    );
  });

  testWidgets('« Suivant » avance d\'une diapo', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.widgetWithText(FrostedButton, 'Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('Ce qui revient,\nrevient tout seul.'), findsOneWidget);
  });

  testWidgets('« Passer » mène au compte, jamais au-delà', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.widgetWithText(FrostedButton, 'Passer'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountSetupSlide), findsOneWidget);
    expect(find.widgetWithText(FrostedButton, 'Passer'), findsNothing);
    expect(find.widgetWithText(FrostedButton, 'Commencer'), findsOneWidget);
  });

  testWidgets('le nom est prérempli, la banque reste à saisir', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.widgetWithText(FrostedButton, 'Passer'));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingPage.defaultAccountName), findsOneWidget);
    expect(primaryButton(tester, 'Commencer').onPressed, isNull);

    await tester.enterText(find.byType(FrostedAutocomplete), 'Boursorama');
    await tester.pumpAndSettle();

    expect(primaryButton(tester, 'Commencer').onPressed, isNotNull);

    await tester.enterText(find.byType(FrostedTextField).first, '  ');
    await tester.pumpAndSettle();

    expect(primaryButton(tester, 'Commencer').onPressed, isNull);
  });

  testWidgets('un compte impossible à créer laisse l\'onboarding ouvert', (
    tester,
  ) async {
    when(() => accountRepository.add(any())).thenThrow(StateError('boum'));

    await pumpOnboarding(tester);

    await tester.tap(find.widgetWithText(FrostedButton, 'Passer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(FrostedAutocomplete), 'Boursorama');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FrostedButton, 'Commencer'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.textContaining('Impossible de créer le compte'), findsOneWidget);
    expect(PreferencesService.isFirstLaunch(), isTrue);

    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
