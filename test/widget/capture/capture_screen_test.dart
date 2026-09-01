import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/capture/capture_screen.dart';
import 'package:mybudget/ui/capture/quick_add_landing.dart';
import 'package:mybudget/ui/capture/widgets/capture_anchor.dart';
import 'package:mybudget/ui/capture/widgets/capture_dock.dart';
import 'package:mybudget/ui/capture/widgets/journal_view.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class FakeAccountNotifier extends AccountNotifier {
  FakeAccountNotifier(this._accounts);

  final List<AccountModel> _accounts;

  @override
  Future<List<AccountModel>> build() async => _accounts;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAccountRepository accounts;
  late MockExpenseRepository expenses;
  late MockRevenueRepository revenues;
  late MockLoanRepository loans;
  late MockLoanEventRepository loanEvents;
  late MockCategoryOverrideRepository overrides;

  setUp(() async {
    await initializeDateFormatting('fr_FR');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();

    accounts = MockAccountRepository();
    expenses = MockExpenseRepository();
    revenues = MockRevenueRepository();
    loans = MockLoanRepository();
    loanEvents = MockLoanEventRepository();
    overrides = MockCategoryOverrideRepository();

    when(() => accounts.getAll()).thenReturn([]);
    when(() => expenses.getActive()).thenReturn([]);
    when(() => expenses.getClosed()).thenReturn([]);
    when(() => loans.getAll()).thenReturn([]);
    when(() => loanEvents.getAll()).thenReturn([]);
    when(() => overrides.getAll()).thenReturn({});

    final salary = RevenueModel.create(
      name: 'Salaire',
      amount: 2480,
      startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      frequency: 'Mensuel',
      accountId: 1,
    );
    salary.id = 1;
    when(() => revenues.getActive()).thenReturn([salary]);
    when(() => revenues.getClosed()).thenReturn([]);
  });

  Future<ProviderContainer> pumpCapture(
    WidgetTester tester, {
    bool keyboardVisible = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        receiptScanAvailableProvider.overrideWithValue(true),
        accountRepositoryProvider.overrideWithValue(accounts),
        expenseRepositoryProvider.overrideWithValue(expenses),
        revenueRepositoryProvider.overrideWithValue(revenues),
        loanRepositoryProvider.overrideWithValue(loans),
        loanEventRepositoryProvider.overrideWithValue(loanEvents),
        categoryOverrideRepositoryProvider.overrideWithValue(overrides),
        accountProvider.overrideWith(() => FakeAccountNotifier([])),
      ],
    );
    addTearDown(container.dispose);

    final landing = QuickAddLandingController();
    addTearDown(landing.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: QuickAddLanding(
            notifier: landing,
            child: FrostedScaffold(
              bottomNavigationBar: FrostedBottomBar(
                folded: keyboardVisible,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: const [
                  FrostedNavItem(
                    icon: Symbols.auto_awesome_rounded,
                    label: 'Accueil',
                  ),
                  FrostedNavItem(
                    icon: Symbols.swap_vert_rounded,
                    label: 'Transactions',
                  ),
                ],
              ),
              body: const CaptureScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows the month figure, the journal and the input', (
    tester,
  ) async {
    await pumpCapture(tester);

    expect(find.byType(CaptureAnchor), findsOneWidget);
    expect(find.byType(JournalView), findsOneWidget);
    expect(find.byType(QuickAddBar), findsOneWidget);
    expect(find.text('RESTE CE MOIS'), findsOneWidget);
    expect(find.textContaining('de revenus'), findsOneWidget);
  });

  testWidgets('keeps the scan next to the input', (tester) async {
    await pumpCapture(tester);

    expect(find.byIcon(Symbols.photo_camera_rounded), findsOneWidget);
  });

  testWidgets('le journal descend jusqu\'en bas sans finir sous le dock', (
    tester,
  ) async {
    await pumpCapture(tester);

    final journal = tester.getRect(find.byType(JournalView));
    final dock = tester.getRect(find.byType(CaptureDock));
    final screen = tester.getRect(find.byType(CaptureScreen));
    final list = tester.widget<ListView>(
      find.descendant(
        of: find.byType(JournalView),
        matching: find.byType(ListView),
      ),
    );
    final reserved = list.padding!.resolve(TextDirection.ltr).bottom;

    expect(journal.bottom, screen.bottom);
    expect(journal.bottom, greaterThan(dock.top));
    expect(journal.bottom - reserved, lessThanOrEqualTo(dock.top));
  });

  Finder dockPanel() => find.descendant(
    of: find.byType(CaptureDock),
    matching: find.byType(FrostedGlass),
  );

  testWidgets('le dock flotte au-dessus de la barre, hors de son verre', (
    tester,
  ) async {
    await pumpCapture(tester);

    final dock = tester.getRect(find.byType(CaptureDock));
    final panel = tester.getRect(dockPanel());
    final bar = tester.getRect(find.byType(FrostedBottomBar));

    expect(dock.bottom, bar.top);
    expect(bar.top - panel.bottom, CaptureDock.clearance);
    expect(panel.top - dock.top, CaptureDock.clearance);
  });

  testWidgets('le dock porte son propre verre, le journal passe derriere', (
    tester,
  ) async {
    await pumpCapture(tester);

    expect(dockPanel(), findsOneWidget);

    final panel = tester.getRect(dockPanel());
    final bar = tester.getRect(find.byType(QuickAddBar));

    expect(panel.top, lessThan(bar.top));
    expect(panel.bottom, greaterThan(bar.bottom));
    expect(panel.left, lessThan(bar.left));
    expect(panel.right, greaterThan(bar.right));
  });

  testWidgets('le clavier replie la barre et le dock prend son bord', (
    tester,
  ) async {
    await pumpCapture(tester, keyboardVisible: true);
    await tester.pumpAndSettle();

    final dock = tester.getRect(find.byType(CaptureDock));
    final screen = tester.getRect(find.byType(CaptureScreen));

    expect(find.byType(QuickAddBar), findsOneWidget);
    expect(tester.getSize(find.byType(FrostedBottomBar)).height, 0);
    expect(dock.bottom, screen.bottom);
  });

  testWidgets('the figure hands the month over to Stats', (tester) async {
    final container = await pumpCapture(tester);

    expect(container.read(homeNavigationProvider).tab, HomeTab.capture);

    await tester.tap(find.byType(CaptureAnchor));
    await tester.pumpAndSettle();

    expect(container.read(homeNavigationProvider).tab, HomeTab.stats);
  });

  testWidgets('les réglages restent en haut à droite', (tester) async {
    final container = await pumpCapture(tester);

    final settings = find.byIcon(Symbols.settings_rounded);
    expect(settings, findsOneWidget);

    await tester.tap(settings);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(container.read(homeNavigationProvider).tab, HomeTab.capture);
  });
}
