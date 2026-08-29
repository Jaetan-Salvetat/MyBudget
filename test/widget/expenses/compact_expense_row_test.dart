import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/expenses/widgets/compact_expense_row.dart';

/// A rule that has been closed is a trace of a month that is over : it can be
/// read, never edited and never deleted again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initializeDateFormatting('fr_FR');
  });

  ExpenseModel rent({DateTime? endDate}) {
    final expense = ExpenseModel.create(
      name: 'Loyer',
      amount: 800,
      startDate: DateTime(2026, 6, 12),
      frequency: 'Mensuel',
      accountId: 1,
      endDate: endDate,
    );
    expense.id = 1;
    return expense;
  }

  Future<void> pumpRow(
    WidgetTester tester,
    ExpenseModel expense, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CompactExpenseRow(
            expense: expense,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }

  testWidgets('an open rule opens its form on a tap', (tester) async {
    var edited = false;
    await pumpRow(
      tester,
      rent(),
      onEdit: () => edited = true,
      onDelete: () {},
    );

    await tester.tap(find.text('Loyer'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
  });

  testWidgets('an open rule offers its actions', (tester) async {
    await pumpRow(tester, rent(), onEdit: () {}, onDelete: () {});

    expect(find.byIcon(Symbols.more_vert_rounded), findsOneWidget);
  });

  testWidgets('a closed rule opens nothing on a tap', (tester) async {
    var edited = false;
    await pumpRow(
      tester,
      rent(endDate: DateTime(2026, 8, 12)),
      onEdit: () => edited = true,
      onDelete: () {},
    );

    await tester.tap(find.text('Loyer'));
    await tester.pumpAndSettle();

    expect(edited, isFalse);
  });

  testWidgets('a closed rule offers no actions at all', (tester) async {
    await pumpRow(
      tester,
      rent(endDate: DateTime(2026, 8, 12)),
      onEdit: () {},
      onDelete: () {},
    );

    expect(find.byIcon(Symbols.more_vert_rounded), findsNothing);
  });
}
