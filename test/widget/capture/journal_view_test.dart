import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transaction_event_repository.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/capture/widgets/journal_landing.dart';
import 'package:mybudget/ui/capture/widgets/journal_view.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/transaction_details/screens/expense_details_screen.dart';
import 'package:mybudget/ui/transaction_details/screens/revenue_details_screen.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

ExpenseModel expenseOf({
  required int id,
  required String name,
  required double amount,
  required DateTime startDate,
  Frequency frequency = Frequency.oneTime,
  String? categorySlug,
}) {
  final expense = ExpenseModel.create(
    name: name,
    amount: amount,
    startDate: startDate,
    frequency: frequency,
    accountId: 1,
    categorySlug: categorySlug,
  );
  expense.id = id;
  return expense;
}

class MockTransactionEventRepository extends Mock
    implements TransactionEventRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository expenses;
  late MockRevenueRepository revenues;
  late MockCategoryOverrideRepository overrides;
  late MockAccountRepository accounts;
  late MockBeneficiaryRepository beneficiaries;
  late MockTransactionEventRepository events;

  final now = DateTime.now();
  DateTime todayAt(int hour, int minute) =>
      DateTime(now.year, now.month, now.day, hour, minute);

  setUp(() async {
    events = MockTransactionEventRepository();
    when(
      () => events.getForRoot(any(), TransactionType.expense),
    ).thenReturn([]);
    when(() => events.getForRoot(any(), TransactionType.income)).thenReturn([]);
    await initializeDateFormatting('fr_FR');
    expenses = MockExpenseRepository();
    revenues = MockRevenueRepository();
    overrides = MockCategoryOverrideRepository();
    accounts = MockAccountRepository();
    beneficiaries = MockBeneficiaryRepository();
    when(() => accounts.getAll()).thenReturn([]);
    when(() => beneficiaries.getAll()).thenReturn([]);

    when(() => expenses.getActive()).thenReturn([]);

    when(() => expenses.getClosed()).thenReturn([]);
    when(() => expenses.delete(any())).thenReturn(true);
    when(() => revenues.getActive()).thenReturn([]);
    when(() => revenues.getClosed()).thenReturn([]);
    when(() => overrides.getAll()).thenReturn({});
  });

  Future<void> pumpJournal(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(expenses),
          revenueRepositoryProvider.overrideWithValue(revenues),
          categoryOverrideRepositoryProvider.overrideWithValue(overrides),
          transactionEventRepositoryProvider.overrideWithValue(events),
          accountRepositoryProvider.overrideWithValue(accounts),
          beneficiaryRepositoryProvider.overrideWithValue(beneficiaries),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: JournalView(bottomInset: 0)),
        ),
      ),
    );
  }

  testWidgets('draws one line per transaction of the day', (tester) async {
    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 1,
        name: 'Carrefour',
        amount: 42.30,
        startDate: todayAt(12, 4),
      ),
      expenseOf(id: 2, name: 'Café', amount: 4, startDate: todayAt(8, 12)),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    expect(find.text('Carrefour'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
  });

  testWidgets('wears the same avatar as the expenses list', (tester) async {
    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 1,
        name: 'Leroy Merlin',
        amount: 31.40,
        startDate: todayAt(15, 8),
      ),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TransactionAvatar), findsOneWidget);
  });

  testWidgets('splits the day where the moment changes', (tester) async {
    when(() => expenses.getActive()).thenReturn([
      expenseOf(id: 1, name: 'Café', amount: 4, startDate: todayAt(8, 12)),
      expenseOf(
        id: 2,
        name: 'Carrefour',
        amount: 42.30,
        startDate: todayAt(14, 0),
      ),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    expect(find.text('CE MATIN'), findsOneWidget);
    expect(find.text('CET APRÈS-MIDI'), findsOneWidget);
  });

  testWidgets('a line that just landed offers the way back', (tester) async {
    when(() => expenses.getActive()).thenReturn([
      expenseOf(id: 7, name: 'Mc do', amount: 12, startDate: todayAt(19, 30)),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    expect(find.text('annuler'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(JournalView)),
    );
    container
        .read(quickAddRecentSubmissionsProvider.notifier)
        .push(
          const QuickAddSubmission(
            id: 7,
            type: TransactionType.expense,
            name: 'Mc do',
            amount: 12,
          ),
        );
    await tester.pump();
    await tester.pump(JournalLanding.duration);

    expect(find.text('annuler'), findsOneWidget);

    await tester.tap(find.text('annuler'));
    await tester.pumpAndSettle();

    verify(() => expenses.delete(7)).called(1);
  });

  testWidgets('une ligne qui arrive ne rallume pas tout le journal', (
    tester,
  ) async {
    when(() => expenses.getActive()).thenReturn([
      expenseOf(id: 7, name: 'Mc do', amount: 12, startDate: todayAt(19, 30)),
      expenseOf(id: 8, name: 'Kiosque', amount: 3, startDate: todayAt(9, 10)),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(JournalView)),
    );
    container
        .read(quickAddRecentSubmissionsProvider.notifier)
        .push(
          const QuickAddSubmission(
            id: 7,
            type: TransactionType.expense,
            name: 'Mc do',
            amount: 12,
          ),
        );
    await tester.pump();

    expect(find.byType(JournalLanding), findsOneWidget);
    expect(
      find.ancestor(of: find.text('Kiosque'), matching: find.byType(Opacity)),
      findsNothing,
    );

    await tester.pump(JournalLanding.duration);
    await tester.pump(QuickAddRecentSubmissions.retention);
  });

  testWidgets('a past month reads open, and folds away on a tap', (
    tester,
  ) async {
    final lastMonth = DateTime(now.year, now.month - 1, 15, 10, 0);

    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 1,
        name: 'Assurance auto',
        amount: 61.20,
        startDate: lastMonth,
      ),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    final label = DateFormat(
      'MMMM yyyy',
      'fr_FR',
    ).format(lastMonth).toUpperCase();

    expect(find.text(label), findsOneWidget);
    expect(find.text('Assurance auto'), findsOneWidget);

    await tester.tap(find.text(label));
    await tester.pumpAndSettle();

    expect(find.text('Assurance auto'), findsNothing);
  });

  testWidgets('a monthly expense shows up in every month since its first', (
    tester,
  ) async {
    final now = DateTime.now();
    final twoMonthsAgo = DateTime(now.year, now.month - 2, 1, 9, 0);

    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 1,
        name: 'Netflix',
        amount: 13.99,
        startDate: twoMonthsAgo,
        frequency: Frequency.monthly,
      ),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsNWidgets(3));
  });

  testWidgets('a yearly expense comes back on the same month, a year on', (
    tester,
  ) async {
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month, 1, 9, 0);

    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 1,
        name: 'Assurance habitation',
        amount: 214,
        startDate: lastYear,
        frequency: Frequency.annual,
      ),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    expect(find.text('Assurance habitation'), findsNWidgets(2));
  });

  testWidgets('an empty today says so, the month carries on below', (
    tester,
  ) async {
    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 1,
        name: 'Decathlon',
        amount: 89.90,
        startDate: todayAt(19, 22).subtract(const Duration(days: 1)),
      ),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    expect(find.text(JournalView.emptyMessage), findsOneWidget);
    expect(find.text('HIER'), findsOneWidget);
    expect(find.text('Decathlon'), findsOneWidget);
  });

  group('le dégradé de bord', () {
    const double height = 600;

    test(
      'laisse la première ligne franche tant que rien n\'est passé dessus',
      () {
        final gradient = JournalView.edgeGradient(scrolled: 0, height: height);

        expect(gradient.stops!.first, 0);
        expect(gradient.colors[1], Colors.black);
      },
    );

    test('dissout le haut à mesure que la liste passe sous le bord', () {
      final gradient = JournalView.edgeGradient(
        scrolled: JournalView.edgeFade,
        height: height,
      );

      expect(gradient.stops![1], JournalView.edgeFade / height);
    });

    test('laisse la liste entière derrière les chromes du bas', () {
      final gradient = JournalView.edgeGradient(scrolled: 0, height: height);

      expect(gradient.stops!.last, 1);
      expect(gradient.colors.last, Colors.black);
    });
  });

  RevenueModel revenueOf({
    required int id,
    required String name,
    required double amount,
    required DateTime startDate,
  }) {
    final revenue = RevenueModel.create(
      name: name,
      amount: amount,
      startDate: startDate,
      accountId: 1,
      frequency: Frequency.oneTime,
    );
    revenue.id = id;
    return revenue;
  }

  testWidgets('a tap on an expense line opens its details', (tester) async {
    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 3,
        name: 'Carrefour',
        amount: 42.30,
        startDate: todayAt(12, 4),
      ),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carrefour'));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseDetailsScreen), findsOneWidget);
  });

  testWidgets('a tap on a revenue line opens its details', (tester) async {
    when(() => revenues.getActive()).thenReturn([
      revenueOf(id: 5, name: 'Prime', amount: 300, startDate: todayAt(9, 0)),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prime'));
    await tester.pumpAndSettle();

    expect(find.byType(RevenueDetailsScreen), findsOneWidget);
  });
}
