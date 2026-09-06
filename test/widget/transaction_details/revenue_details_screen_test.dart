import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/repository/account_repository.dart';
import 'package:mybudget/data/repository/beneficiary_repository.dart';
import 'package:mybudget/data/repository/category_override_repository.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/loan_event_repository.dart';
import 'package:mybudget/data/repository/loan_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/data/repository/transaction_event_repository.dart';
import 'package:mybudget/data/repository/transfer_repository.dart';
import 'package:mybudget/data/service/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/ui/transaction_details/screens/revenue_details_screen.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockTransferRepository extends Mock implements TransferRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockTransactionEventRepository extends Mock
    implements TransactionEventRepository {}

void main() {
  late MockAccountRepository accountRepository;
  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockLoanRepository loanRepository;
  late MockLoanEventRepository loanEventRepository;
  late MockTransferRepository transferRepository;
  late MockCategoryOverrideRepository categoryOverrideRepository;
  late MockBeneficiaryRepository beneficiaryRepository;
  late CategoryTaxonomyService taxonomy;

  final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  late MockTransactionEventRepository events;

  setUp(() {
    events = MockTransactionEventRepository();
    when(
      () => events.getForRoot(any(), TransactionType.expense),
    ).thenReturn([]);
    when(() => events.getForRoot(any(), TransactionType.income)).thenReturn([]);
    accountRepository = MockAccountRepository();
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    loanRepository = MockLoanRepository();
    loanEventRepository = MockLoanEventRepository();
    transferRepository = MockTransferRepository();
    categoryOverrideRepository = MockCategoryOverrideRepository();
    beneficiaryRepository = MockBeneficiaryRepository();

    when(() => accountRepository.getAll()).thenReturn([
      AccountModel.create(name: 'Courant', bank: 'Banque')..id = 1,
    ]);
    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => expenseRepository.getClosed()).thenReturn([]);
    when(() => loanRepository.getAll()).thenReturn([]);
    when(() => loanEventRepository.getAll()).thenReturn([]);
    when(() => transferRepository.getAll()).thenReturn([]);
    when(() => categoryOverrideRepository.getAll()).thenReturn({});
    when(() => beneficiaryRepository.getAll()).thenReturn([]);
  });

  DateTime monthsAgo(int months, int day) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - months, day);
  }

  RevenueModel salary({DateTime? endDate}) {
    final revenue = RevenueModel.create(
      name: 'Salaire',
      amount: 2400,
      categorySlug: 'salaire.salaire_net',
      startDate: monthsAgo(2, 1),
      accountId: 1,
      frequency: Frequency.monthly,
      endDate: endDate,
    );
    revenue.id = 1;
    return revenue;
  }

  Future<void> pumpDetails(
    WidgetTester tester, {
    required List<RevenueModel> open,
    List<RevenueModel> closed = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => revenueRepository.getActive()).thenReturn(open);
    when(() => revenueRepository.getClosed()).thenReturn(closed);

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
            categoryOverrideRepository,
          ),
          transactionEventRepositoryProvider.overrideWithValue(events),
          beneficiaryRepositoryProvider.overrideWithValue(
            beneficiaryRepository,
          ),
          categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const RevenueDetailsScreen(revenueId: 1, isCurrentMonth: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names the revenue it details', (tester) async {
    await pumpDetails(tester, open: [salary()]);

    expect(find.text('Salaire'), findsWidgets);
    expect(find.text('Salaire · Salaire net'), findsOneWidget);
    expect(find.text('Courant · Banque'), findsOneWidget);
  });

  testWidgets('signs the amount as money coming in', (tester) async {
    await pumpDetails(tester, open: [salary()]);

    expect(find.text('+${formatter.format(2400)}'), findsOneWidget);
  });

  testWidgets('sums up what has been cashed in so far', (tester) async {
    await pumpDetails(tester, open: [salary()]);

    expect(find.text(formatter.format(7200)), findsOneWidget);
    expect(find.text('3 échéances passées'), findsOneWidget);
  });

  testWidgets('offers nothing to change on a closed revenue', (tester) async {
    await pumpDetails(
      tester,
      open: const [],
      closed: [salary(endDate: monthsAgo(1, 15))],
    );

    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Supprimer'), findsNothing);
  });
}
