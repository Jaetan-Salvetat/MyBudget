import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_group_by_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<RevenueGroupBy>> openMenu(WidgetTester tester) async {
    final selections = <RevenueGroupBy>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => RevenueGroupByMenu.show(
                context: context,
                current: RevenueGroupBy.frequency,
                onSelect: selections.add,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return selections;
  }

  testWidgets('lists every axis in a single list section', (tester) async {
    await openMenu(tester);

    expect(find.byType(FrostedListSection), findsOneWidget);
    for (final axis in RevenueGroupBy.values) {
      expect(find.text(axis.label), findsOneWidget);
    }
  });

  testWidgets('closes on a selection and reports the axis', (tester) async {
    final selections = await openMenu(tester);

    await tester.tap(find.text(RevenueGroupBy.beneficiary.label));
    await tester.pumpAndSettle();

    expect(selections, [RevenueGroupBy.beneficiary]);
    expect(find.byType(FrostedListSection), findsNothing);
  });
}
