import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';

void main() {
  testWidgets('kNavPillFootprint matches the rendered pill plus its margin', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FrostedNavPill(
              destinations: const [
                FrostedNavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Accueil',
                ),
                FrostedNavItem(
                  icon: Icons.swap_vert_outlined,
                  label: 'Transactions',
                ),
                FrostedNavItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Comptes',
                ),
              ],
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const double bottomMargin = FrostedSpacing.sp3;
    final double pillHeight = tester
        .getSize(find.byType(FrostedNavPill))
        .height;

    expect(pillHeight + bottomMargin, kNavPillFootprint);
  });
}
