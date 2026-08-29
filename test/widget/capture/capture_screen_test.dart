import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'package:mybudget/ui/capture/widgets/capture_anchor.dart';
import 'package:mybudget/ui/capture/widgets/journal_view.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';
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

  Future<ProviderContainer> pumpCapture(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: CaptureScreen()),
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

  testWidgets('the figure hands the month over to Stats', (tester) async {
    final container = await pumpCapture(tester);

    expect(container.read(homeNavigationProvider).tab, HomeTab.capture);

    await tester.tap(find.byType(CaptureAnchor));
    await tester.pumpAndSettle();

    expect(container.read(homeNavigationProvider).tab, HomeTab.stats);
  });
}
