import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/common/widgets/effective_month_field.dart';
import 'package:mybudget/ui/common/widgets/recurring_edit_scope_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  final today = DateTime.now();

  ExpenseModel subscription({
    double amount = 20,
    Frequency frequency = Frequency.monthly,
    DateTime? startDate,
  }) {
    return ExpenseModel.create(
      name: 'VPS',
      amount: amount,
      startDate: startDate ?? DateTime(today.year, today.month - 2, 1),
      frequency: frequency,
      accountId: 1,
    )..id = 7;
  }

  Future<List<EffectiveMonth?>> submitEdit(
    WidgetTester tester, {
    required ExpenseModel before,
    required ExpenseModel after,
  }) async {
    final confirmed = <EffectiveMonth?>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => RecurringEditScopeDialog.submit(
              context: context,
              before: before,
              after: after,
              now: DateTime.now(),
              onConfirmed: (scope) async => confirmed.add(scope),
            ),
            child: const Text('Modifier'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    return confirmed;
  }

  testWidgets('saves straight away when the terms did not move', (
    tester,
  ) async {
    final expense = subscription();
    final confirmed = await submitEdit(
      tester,
      before: expense,
      after: expense.copyWith(categorySlug: 'logement.loyer'),
    );

    expect(find.byType(EffectiveMonthField), findsNothing);
    expect(confirmed, [null]);
  });

  testWidgets('saves straight away on a one-off', (tester) async {
    final expense = subscription(frequency: Frequency.oneTime);
    final confirmed = await submitEdit(
      tester,
      before: expense,
      after: expense.copyWith(amount: 35),
    );

    expect(find.byType(EffectiveMonthField), findsNothing);
    expect(confirmed, [null]);
  });

  testWidgets('asks which month new terms belong to', (tester) async {
    final expense = subscription();
    final confirmed = await submitEdit(
      tester,
      before: expense,
      after: expense.copyWith(amount: 35),
    );

    expect(find.byType(EffectiveMonthField), findsOneWidget);
    expect(confirmed, isEmpty);
  });

  testWidgets('saves on the month in progress when the switch is left on', (
    tester,
  ) async {
    final expense = subscription(
      startDate: DateTime(today.year, today.month, today.day),
    );
    final confirmed = await submitEdit(
      tester,
      before: expense,
      after: expense.copyWith(amount: 35),
    );

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(confirmed, [EffectiveMonth.thisMonth]);
  });

  testWidgets('saves on the month after once the switch is turned off', (
    tester,
  ) async {
    final expense = subscription(
      startDate: DateTime(today.year, today.month, today.day),
    );
    final confirmed = await submitEdit(
      tester,
      before: expense,
      after: expense.copyWith(amount: 35),
    );

    await tester.tap(find.byType(FrostedSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(confirmed, [EffectiveMonth.nextMonth]);
  });

  testWidgets('saves nothing when the edit is called off', (tester) async {
    final expense = subscription();
    final confirmed = await submitEdit(
      tester,
      before: expense,
      after: expense.copyWith(amount: 35),
    );

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(confirmed, isEmpty);
  });
}
