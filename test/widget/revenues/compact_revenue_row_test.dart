import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/revenues/widgets/compact_revenue_row.dart';

/// The revenue row reads the same as the expense one : a rule that has been
/// closed is a trace of a month that is over : it can be
/// read, never edited and never deleted again. So is anything read from a
/// month other than the one in progress.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initializeDateFormatting('fr_FR');
  });

  RevenueModel salary({DateTime? endDate}) {
    final revenue = RevenueModel.create(
      name: 'Chomage',
      amount: 963,
      startDate: DateTime(2026, 6, 12),
      frequency: 'Mensuel',
      accountId: 1,
      endDate: endDate,
    );
    revenue.id = 1;
    return revenue;
  }

  Future<void> pumpRow(
    WidgetTester tester,
    RevenueModel revenue, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    bool isCurrentMonth = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CompactRevenueRow(
            revenue: revenue,
            isCurrentMonth: isCurrentMonth,
            accountName: 'Compte courant',
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
      salary(),
      onEdit: () => edited = true,
      onDelete: () {},
    );

    await tester.tap(find.text('Chomage'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
  });

  testWidgets('an open rule offers its actions', (tester) async {
    await pumpRow(tester, salary(), onEdit: () {}, onDelete: () {});

    expect(find.byIcon(Symbols.more_vert_rounded), findsOneWidget);
  });

  testWidgets('a closed rule opens nothing on a tap', (tester) async {
    var edited = false;
    await pumpRow(
      tester,
      salary(endDate: DateTime(2026, 8, 12)),
      onEdit: () => edited = true,
      onDelete: () {},
    );

    await tester.tap(find.text('Chomage'));
    await tester.pumpAndSettle();

    expect(edited, isFalse);
  });

  testWidgets('a closed rule offers no actions at all', (tester) async {
    await pumpRow(
      tester,
      salary(endDate: DateTime(2026, 8, 12)),
      onEdit: () {},
      onDelete: () {},
    );

    expect(find.byIcon(Symbols.more_vert_rounded), findsNothing);
  });

  testWidgets('a past month opens nothing on a tap', (tester) async {
    var edited = false;
    await pumpRow(
      tester,
      salary(),
      onEdit: () => edited = true,
      onDelete: () {},
      isCurrentMonth: false,
    );

    await tester.tap(find.text('Chomage'));
    await tester.pumpAndSettle();

    expect(edited, isFalse);
  });

  testWidgets('a past month offers no actions either', (tester) async {
    await pumpRow(
      tester,
      salary(),
      onEdit: () {},
      onDelete: () {},
      isCurrentMonth: false,
    );

    expect(find.byIcon(Symbols.more_vert_rounded), findsNothing);
  });
}
