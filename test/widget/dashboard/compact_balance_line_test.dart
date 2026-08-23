import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/ui/dashboard/widgets/compact_balance_line.dart';

void main() {
  Future<void> pumpLine(WidgetTester tester, double balance) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: CompactBalanceLine(balance: balance)),
      ),
    );
  }

  testWidgets('says what the amount is', (tester) async {
    await pumpLine(tester, 482);

    expect(find.text('RESTE À VIVRE'), findsOneWidget);
  });

  testWidgets('shows a positive balance in the income colour', (tester) async {
    await pumpLine(tester, 482);

    final element = tester.element(find.byType(CompactBalanceLine));
    final amount = tester.widget<Text>(find.textContaining('482'));

    expect(amount.style!.color, element.financeColors.income);
  });

  testWidgets('shows a negative balance in the expense colour', (tester) async {
    await pumpLine(tester, -120.99);

    final element = tester.element(find.byType(CompactBalanceLine));
    final amount = tester.widget<Text>(find.textContaining('120,99'));

    expect(amount.style!.color, element.financeColors.expense);
  });
}
