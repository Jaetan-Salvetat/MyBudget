import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/expense_group_by.dart';
import 'package:mybudget/core/providers/expenses_view_provider.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/transactions/transactions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockTransferRepository extends Mock implements TransferRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    await initializeDateFormatting('fr_FR');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();

    final accounts = MockAccountRepository();
    final expenses = MockExpenseRepository();
    final revenues = MockRevenueRepository();
    final loans = MockLoanRepository();
    final loanEvents = MockLoanEventRepository();
    final overrides = MockCategoryOverrideRepository();
    final transfers = MockTransferRepository();
    final beneficiaries = MockBeneficiaryRepository();

    when(accounts.getAll).thenReturn([]);
    when(expenses.getActive).thenReturn([]);
    when(expenses.getClosed).thenReturn([]);
    when(loans.getAll).thenReturn([]);
    when(loanEvents.getAll).thenReturn([]);
    when(overrides.getAll).thenReturn({});
    when(revenues.getActive).thenReturn([]);
    when(revenues.getClosed).thenReturn([]);
    when(transfers.getAll).thenReturn([]);
    when(beneficiaries.getAll).thenReturn([]);

    container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accounts),
        expenseRepositoryProvider.overrideWithValue(expenses),
        revenueRepositoryProvider.overrideWithValue(revenues),
        loanRepositoryProvider.overrideWithValue(loans),
        loanEventRepositoryProvider.overrideWithValue(loanEvents),
        categoryOverrideRepositoryProvider.overrideWithValue(overrides),
        transferRepositoryProvider.overrideWithValue(transfers),
        beneficiaryRepositoryProvider.overrideWithValue(beneficiaries),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpTransactions(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: TransactionsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('le groupement des dépenses passe au jour ou à la semaine', (
    tester,
  ) async {
    await pumpTransactions(tester);

    expect(find.byType(FrostedSegmentedControl), findsOneWidget);
    expect(container.read(expensesGroupByProvider), ExpenseGroupBy.day);

    await tester.tapAt(tester.getCenter(find.text(ExpenseGroupBy.week.label)));
    await tester.pumpAndSettle();

    expect(container.read(expensesGroupByProvider), ExpenseGroupBy.week);

    await tester.tapAt(tester.getCenter(find.text(ExpenseGroupBy.day.label)));
    await tester.pumpAndSettle();

    expect(container.read(expensesGroupByProvider), ExpenseGroupBy.day);
  });
}
