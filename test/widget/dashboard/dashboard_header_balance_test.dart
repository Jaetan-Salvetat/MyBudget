import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/dashboard/widgets/compact_balance_line.dart';
import 'package:mybudget/ui/dashboard/widgets/dashboard_header_balance.dart';
import 'package:mybudget/ui/dashboard/widgets/hero_balance_card.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, {required bool typing}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardHeaderBalance(
              typing: typing,
              balance: -120.99,
              totalIncomes: 0,
              totalExpenses: 121,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the full card while the user is not typing', (
    tester,
  ) async {
    await pumpHeader(tester, typing: false);
    await tester.pumpAndSettle();

    expect(find.byType(HeroBalanceCard), findsOneWidget);
    expect(find.byType(CompactBalanceLine), findsNothing);
  });

  testWidgets('shows the one-line balance while typing', (tester) async {
    await pumpHeader(tester, typing: true);
    await tester.pumpAndSettle();

    expect(find.byType(CompactBalanceLine), findsOneWidget);
    expect(find.byType(HeroBalanceCard), findsNothing);
  });

  testWidgets('never prints the balance twice mid-transition', (tester) async {
    await pumpHeader(tester, typing: true);
    await tester.pumpAndSettle();

    await pumpHeader(tester, typing: false);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        find.byType(HeroBalanceCard).evaluate().length +
            find.byType(CompactBalanceLine).evaluate().length,
        1,
      );
    }
  });

  testWidgets('never composites the card through an opacity layer', (
    tester,
  ) async {
    // The card is glass : a backdrop filter inside an opacity layer samples
    // that layer instead of the screen and paints a grey block over it.
    await pumpHeader(tester, typing: true);
    await tester.pumpAndSettle();

    await pumpHeader(tester, typing: false);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        find.descendant(
          of: find.byType(DashboardHeaderBalance),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DashboardHeaderBalance),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    }
  });
}
