import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/repository/account_repository.dart';
import 'package:mybudget/data/repository/beneficiary_repository.dart';
import 'package:mybudget/data/repository/category_override_repository.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/loan_event_repository.dart';
import 'package:mybudget/data/repository/loan_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/data/repository/transfer_repository.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/capture/capture_screen.dart';
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

class FakeAccountNotifier extends AccountNotifier {
  FakeAccountNotifier(this._accounts);

  final List<AccountModel> _accounts;

  @override
  List<AccountModel> build() => _accounts;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAccountRepository accounts;
  late MockExpenseRepository expenses;
  late MockRevenueRepository revenues;
  late MockLoanRepository loans;
  late MockLoanEventRepository loanEvents;
  late MockCategoryOverrideRepository overrides;
  late MockTransferRepository transfers;
  late MockBeneficiaryRepository beneficiaries;

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
    transfers = MockTransferRepository();
    beneficiaries = MockBeneficiaryRepository();

    when(() => accounts.getAll()).thenReturn([]);
    when(() => expenses.getActive()).thenReturn([]);
    when(() => expenses.getClosed()).thenReturn([]);
    when(() => loans.getAll()).thenReturn([]);
    when(() => loanEvents.getAll()).thenReturn([]);
    when(() => overrides.getAll()).thenReturn({});
    when(() => revenues.getActive()).thenReturn([]);
    when(() => revenues.getClosed()).thenReturn([]);
    when(() => transfers.getAll()).thenReturn([]);
    when(() => beneficiaries.getAll()).thenReturn([]);
  });

  Future<Rect> pumpTab(WidgetTester tester, Widget tab) async {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accounts),
        expenseRepositoryProvider.overrideWithValue(expenses),
        revenueRepositoryProvider.overrideWithValue(revenues),
        loanRepositoryProvider.overrideWithValue(loans),
        loanEventRepositoryProvider.overrideWithValue(loanEvents),
        categoryOverrideRepositoryProvider.overrideWithValue(overrides),
        transferRepositoryProvider.overrideWithValue(transfers),
        beneficiaryRepositoryProvider.overrideWithValue(beneficiaries),
        accountProvider.overrideWith(() => FakeAccountNotifier([])),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: tab),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return tester.getRect(
      find
          .ancestor(
            of: find.byIcon(Symbols.settings_rounded),
            matching: find.byType(FrostedIconButton),
          )
          .first,
    );
  }

  testWidgets('les onglets du main flow posent leur topbar au même endroit', (
    tester,
  ) async {
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;

    final capture = await pumpTab(tester, const CaptureScreen());
    final transactions = await pumpTab(tester, const TransactionsScreen());
    final accountsTab = await pumpTab(tester, const AccountsScreen());

    for (final rect in [capture, transactions, accountsTab]) {
      expect(
        screenWidth - rect.right,
        moreOrLessEquals(kMainFlowGutter, epsilon: 1),
        reason: 'le bouton réglages doit être à la gouttière du bord droit',
      );
    }

    expect(capture.top, moreOrLessEquals(transactions.top, epsilon: 1));
    expect(capture.top, moreOrLessEquals(accountsTab.top, epsilon: 1));
  });
}
