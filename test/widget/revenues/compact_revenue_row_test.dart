import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/revenues/widgets/compact_revenue_row.dart';

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
    VoidCallback? onOpen,
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
      salary(),
      onOpen: () => opened = true,
      onEdit: () {},
      onDelete: () {},
    );

    await tester.tap(find.text('Chomage'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('an open rule offers its actions', (tester) async {
    await pumpRow(tester, salary(), onEdit: () {}, onDelete: () {});

    expect(find.byIcon(Symbols.more_vert_rounded), findsOneWidget);
  });

  testWidgets('a closed rule still opens its details', (tester) async {
    var opened = false;
    await pumpRow(
      tester,
      salary(endDate: DateTime(2026, 8, 12)),
      onOpen: () => opened = true,
      onEdit: () {},
      onDelete: () {},
    );

    await tester.tap(find.text('Chomage'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
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

  testWidgets('a past month still opens its details', (tester) async {
    var opened = false;
    await pumpRow(
      tester,
      salary(),
      onOpen: () => opened = true,
      onEdit: () {},
      onDelete: () {},
      isCurrentMonth: false,
    );

    await tester.tap(find.text('Chomage'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
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
