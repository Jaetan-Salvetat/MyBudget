import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/stats/stats_screen.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/loans/screens/loan_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DisabledQuickAdd extends QuickAddEnabledNotifier {
  @override
  bool build() => false;
}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

void main() {
  late MockAccountRepository accountRepository;
  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockLoanRepository loanRepository;
  late MockLoanEventRepository loanEventRepository;
  late MockCategoryOverrideRepository categoryOverrideRepository;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    accountRepository = MockAccountRepository();
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    loanRepository = MockLoanRepository();
    loanEventRepository = MockLoanEventRepository();
    categoryOverrideRepository = MockCategoryOverrideRepository();

    when(() => accountRepository.getAll()).thenReturn([]);
    when(() => expenseRepository.getAll()).thenReturn([]);
    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => expenseRepository.getClosed()).thenReturn([]);
    when(() => revenueRepository.getAll()).thenReturn([]);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getClosed()).thenReturn([]);
    when(() => loanEventRepository.getAll()).thenReturn([]);
    when(() => categoryOverrideRepository.getAll()).thenReturn({});
    when(() => loanRepository.getAll()).thenReturn([
      LoanModel(
        id: 7,
        name: 'Prêt auto',
        amount: 5000,
        duration: 12,
        interestRate: 5,
        accountId: 1,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2027, 1, 1),
        dayOfMonth: 1,
        lenderName: 'Banque',
      ),
    ]);
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accountRepository),
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        revenueRepositoryProvider.overrideWithValue(revenueRepository),
        loanRepositoryProvider.overrideWithValue(loanRepository),
        loanEventRepositoryProvider.overrideWithValue(loanEventRepository),
        categoryOverrideRepositoryProvider.overrideWithValue(
          categoryOverrideRepository,
        ),
        quickAddEnabledProvider.overrideWith(() => _DisabledQuickAdd()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loanProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: StatsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a loan opens its details', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpDashboard(tester);

    await tester.tap(find.text('Prêt auto'));
    await tester.pumpAndSettle();

    expect(find.byType(LoanDetailsScreen), findsOneWidget);
    await tester.pump(const Duration(minutes: 5));
  });
}
