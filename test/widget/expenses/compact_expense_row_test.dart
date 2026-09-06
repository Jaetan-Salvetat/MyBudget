import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/expenses/widgets/compact_expense_row.dart';

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

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
      frequency: Frequency.monthly,
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
    VoidCallback? onOpen,
    bool isCurrentMonth = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CompactExpenseRow(
            expense: expense,
            isCurrentMonth: isCurrentMonth,
            now: _fixedNow,
            onOpen: onOpen ?? () {},
            onEdit: onEdit,
            onDelete: (_) => onDelete(),
          ),
        ),
      ),
    );
  }

  testWidgets('an open rule opens its details on a tap', (tester) async {
    var opened = false;
    await pumpRow(
      tester,
      rent(),
      onOpen: () => opened = true,
      onEdit: () {},
      onDelete: () {},
    );

    await tester.tap(find.text('Loyer'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('an open rule offers its actions', (tester) async {
    await pumpRow(tester, rent(), onEdit: () {}, onDelete: () {});

    expect(find.byIcon(Symbols.more_vert_rounded), findsOneWidget);
  });

  testWidgets('a closed rule still opens its details', (tester) async {
    var opened = false;
    await pumpRow(
      tester,
      rent(endDate: DateTime(2026, 8, 12)),
      onOpen: () => opened = true,
      onEdit: () {},
      onDelete: () {},
    );

    await tester.tap(find.text('Loyer'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
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

  testWidgets('a past month still opens its details', (tester) async {
    var opened = false;
    await pumpRow(
      tester,
      rent(),
      onOpen: () => opened = true,
      onEdit: () {},
      onDelete: () {},
      isCurrentMonth: false,
    );

    await tester.tap(find.text('Loyer'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
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

  testWidgets('a closed rule keeps its amount aligned with an open one', (
    tester,
  ) async {
    await pumpRow(tester, rent(), onEdit: () {}, onDelete: () {});
    final openAmount = tester.getTopRight(find.textContaining('800,00'));

    await pumpRow(
      tester,
      rent(endDate: DateTime(2026, 8, 12)),
      onEdit: () {},
      onDelete: () {},
    );
    final closedAmount = tester.getTopRight(find.textContaining('800,00'));

    expect(closedAmount.dx, openAmount.dx);
  });
}
