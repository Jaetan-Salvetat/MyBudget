import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/transaction_event_repository.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/core/entities/transaction_change_entry.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/transaction_event_model.dart';
import 'package:mybudget/ui/transaction_details/screens/expense_details_screen.dart';

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
    when(
      () => events.getForRoot(any(), TransactionType.income),
    ).thenReturn([]);
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
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getClosed()).thenReturn([]);
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

  ExpenseModel rent({
    required int id,
    double amount = 800,
    DateTime? startDate,
    DateTime? endDate,
    int? parentId,
  }) {
    final expense = ExpenseModel.create(
      name: 'Loyer',
      amount: amount,
      categorySlug: 'logement.loyer',
      startDate: startDate ?? monthsAgo(3, 1),
      frequency: 'Mensuel',
      accountId: 1,
      endDate: endDate,
      parentId: parentId,
    );
    expense.id = id;
    return expense;
  }

  Future<void> pumpDetails(
    WidgetTester tester, {
    required List<ExpenseModel> open,
    List<ExpenseModel> closed = const [],
    int expenseId = 1,
    bool isCurrentMonth = true,
  }) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => expenseRepository.getActive()).thenReturn(open);
    when(() => expenseRepository.getClosed()).thenReturn(closed);

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
          beneficiaryRepositoryProvider.overrideWithValue(beneficiaryRepository),
          categoryTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ExpenseDetailsScreen(
            expenseId: expenseId,
            isCurrentMonth: isCurrentMonth,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names the rule it details', (tester) async {
    await pumpDetails(tester, open: [rent(id: 1)]);

    expect(find.text('Loyer'), findsWidgets);
    expect(find.text('Logement · Loyer'), findsOneWidget);
    expect(find.text('Courant · Banque'), findsOneWidget);
  });

  testWidgets('sums up what the rule has cost so far', (tester) async {
    await pumpDetails(tester, open: [rent(id: 1)]);

    expect(find.text(formatter.format(3200)), findsOneWidget);
    expect(find.text('4 échéances passées'), findsOneWidget);
  });

  testWidgets('adds up the whole chain of revisions', (tester) async {
    await pumpDetails(
      tester,
      expenseId: 2,
      open: [
        rent(id: 2, amount: 900, startDate: monthsAgo(2, 1), parentId: 1),
      ],
      closed: [
        rent(
          id: 1,
          startDate: monthsAgo(6, 1),
          endDate: monthsAgo(3, 15),
        ),
      ],
    );

    expect(find.text(formatter.format(5900)), findsOneWidget);
    expect(find.text('7 échéances passées'), findsOneWidget);
  });

  testWidgets('tells the price a revised rule left behind', (tester) async {
    await pumpDetails(
      tester,
      expenseId: 2,
      open: [
        rent(id: 2, amount: 900, startDate: monthsAgo(2, 1), parentId: 1),
      ],
      closed: [
        rent(
          id: 1,
          startDate: monthsAgo(6, 1),
          endDate: monthsAgo(3, 15),
        ),
      ],
    );

    expect(find.text('HISTORIQUE'), findsOneWidget);
    expect(find.text('Montant'), findsWidgets);
    expect(
      find.text('${formatter.format(800)} → ${formatter.format(900)}'),
      findsOneWidget,
    );
    expect(find.text('Création'), findsOneWidget);
  });

  testWidgets('tells a recorded change of category', (tester) async {
    when(
      () => events.getForRoot(any(), TransactionType.expense),
    ).thenReturn([
      TransactionEventModel.create(
        rootId: 1,
        type: TransactionType.expense,
        entry: TransactionChangeEntry(
          at: monthsAgo(1, 4),
          change: TransactionChange.category,
          from: 'logement.loyer',
          to: 'logement.charges',
        ),
      ),
    ]);

    await pumpDetails(tester, open: [rent(id: 1)]);

    expect(find.text('Catégorie'), findsWidgets);
    expect(find.text('Loyer → Charges'), findsOneWidget);
  });

  testWidgets('keeps the history out of an untouched rule', (tester) async {
    await pumpDetails(tester, open: [rent(id: 1)]);

    expect(find.text('HISTORIQUE'), findsNothing);
  });

  testWidgets('offers to edit and delete an open rule', (tester) async {
    await pumpDetails(tester, open: [rent(id: 1)]);

    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });

  testWidgets('offers nothing to change on a closed rule', (tester) async {
    await pumpDetails(
      tester,
      open: const [],
      closed: [rent(id: 1, endDate: monthsAgo(1, 15))],
    );

    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Supprimer'), findsNothing);
  });

  testWidgets('offers nothing to change from a past month', (tester) async {
    await pumpDetails(tester, open: [rent(id: 1)], isCurrentMonth: false);

    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Supprimer'), findsNothing);
  });

  testWidgets('scopes the deletion of a recurring rule', (tester) async {
    await pumpDetails(tester, open: [rent(id: 1)]);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Retirer aussi le mois en cours'), findsOneWidget);
  });

  testWidgets('has nothing to scope on a one-off', (tester) async {
    final groceries = ExpenseModel.create(
      name: 'Courses',
      amount: 42,
      categorySlug: 'logement.loyer',
      startDate: DateTime.now(),
      frequency: 'Ponctuel',
      accountId: 1,
    )..id = 1;

    await pumpDetails(tester, open: [groceries]);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la suppression'), findsOneWidget);
    expect(find.text('Retirer aussi le mois en cours'), findsNothing);
  });
}
