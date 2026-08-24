import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_submission_ticker.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

void main() {
  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;

  setUp(() {
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => expenseRepository.delete(any())).thenReturn(true);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.delete(any())).thenReturn(true);
  });

  Future<ProviderContainer> pumpTicker(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(expenseRepository),
          revenueRepositoryProvider.overrideWithValue(revenueRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: QuickAddSubmissionTicker()),
        ),
      ),
    );
    return ProviderScope.containerOf(
      tester.element(find.byType(QuickAddSubmissionTicker)),
    );
  }

  const expense = QuickAddSubmission(
    id: 7,
    type: TransactionType.expense,
    name: 'café',
    amount: 3.5,
  );

  const income = QuickAddSubmission(
    id: 9,
    type: TransactionType.income,
    name: 'salaire',
    amount: 2500,
  );

  testWidgets('shows nothing while nothing was just recorded', (tester) async {
    await pumpTicker(tester);

    expect(find.text('Annuler'), findsNothing);
  });

  String currency(double amount) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(amount);

  testWidgets('names what landed, signed by its direction', (tester) async {
    final container = await pumpTicker(tester);

    container.read(quickAddRecentSubmissionsProvider.notifier)
      ..push(expense)
      ..push(income);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('café'), findsOneWidget);
    expect(find.textContaining('− ${currency(3.5)}'), findsOneWidget);
    expect(find.textContaining('salaire'), findsOneWidget);
    expect(find.textContaining('+ ${currency(2500)}'), findsOneWidget);
    expect(find.text('Annuler'), findsNWidgets(2));

    await tester.pump(QuickAddRecentSubmissions.retention);
  });

  testWidgets('the line lets go on its own after the retention', (
    tester,
  ) async {
    final container = await pumpTicker(tester);

    container.read(quickAddRecentSubmissionsProvider.notifier).push(expense);
    await tester.pump();
    await tester.pump(QuickAddRecentSubmissions.retention);
    await tester.pumpAndSettle();

    expect(find.textContaining('café'), findsNothing);
  });

  testWidgets('undoing deletes the transaction and drops the line', (
    tester,
  ) async {
    final container = await pumpTicker(tester);

    container.read(quickAddRecentSubmissionsProvider.notifier).push(expense);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    verify(() => expenseRepository.delete(7)).called(1);
    expect(find.textContaining('café'), findsNothing);
    expect(container.read(quickAddRecentSubmissionsProvider), isEmpty);
  });

  testWidgets('undoing an income goes through the revenues', (tester) async {
    final container = await pumpTicker(tester);

    container.read(quickAddRecentSubmissionsProvider.notifier).push(income);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    verify(() => revenueRepository.delete(9)).called(1);
  });
}
