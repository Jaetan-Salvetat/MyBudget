import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/expenses/widgets/compact_expense_row.dart';

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
    bool isCurrentMonth = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CompactExpenseRow(
            expense: expense,
            isCurrentMonth: isCurrentMonth,
            onEdit: onEdit,
            onDelete: (_) => onDelete(),
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

  testWidgets('a past month opens nothing on a tap', (tester) async {
    var edited = false;
    await pumpRow(
      tester,
      rent(),
      onEdit: () => edited = true,
      onDelete: () {},
      isCurrentMonth: false,
    );

    await tester.tap(find.text('Loyer'));
    await tester.pumpAndSettle();

    expect(edited, isFalse);
  });

  testWidgets('a past month offers no actions either', (tester) async {
    await pumpRow(
      tester,
      rent(),
      onEdit: () {},
      onDelete: () {},
      isCurrentMonth: false,
    );

    expect(find.byIcon(Symbols.more_vert_rounded), findsNothing);
  });
}
