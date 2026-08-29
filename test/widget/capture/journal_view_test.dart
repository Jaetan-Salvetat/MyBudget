import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/ui/capture/widgets/journal_view.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

ExpenseModel expenseOf({
  required int id,
  required String name,
  required double amount,
  required DateTime startDate,
  String frequency = 'Ponctuel',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository expenses;
  late MockRevenueRepository revenues;
  late MockCategoryOverrideRepository overrides;

  final now = DateTime.now();
  DateTime todayAt(int hour, int minute) =>
      DateTime(now.year, now.month, now.day, hour, minute);

  setUp(() async {
    await initializeDateFormatting('fr_FR');
    expenses = MockExpenseRepository();
    revenues = MockRevenueRepository();
    overrides = MockCategoryOverrideRepository();

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
        categorySlug: 'alimentation.supermarche',
      ),
      expenseOf(
        id: 2,
        name: 'Café',
        amount: 4,
        startDate: todayAt(8, 12),
        categorySlug: 'restauration.cafe',
      ),
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
        categorySlug: 'logement.entretien',
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

    expect(find.text('Annuler'), findsNothing);

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
            categorySlug: 'restauration.fast_food',
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('Annuler'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    verify(() => expenses.delete(7)).called(1);
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
    final twoMonthsAgo = DateTime(now.year, now.month - 2, 3, 9, 0);

    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 1,
        name: 'Netflix',
        amount: 13.99,
        startDate: twoMonthsAgo,
        frequency: 'Mensuel',
      ),
    ]);

    await pumpJournal(tester);
    await tester.pumpAndSettle();

    // Its own month, the one after, and the current one.
    expect(find.text('Netflix'), findsNWidgets(3));
  });

  testWidgets('a yearly expense comes back on the same month, a year on', (
    tester,
  ) async {
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month, 12, 9, 0);

    when(() => expenses.getActive()).thenReturn([
      expenseOf(
        id: 1,
        name: 'Assurance habitation',
        amount: 214,
        startDate: lastYear,
        frequency: 'Annuel',
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
}
