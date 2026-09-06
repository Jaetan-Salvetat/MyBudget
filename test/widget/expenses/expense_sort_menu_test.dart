import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/expense_sort_by.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/expenses/widgets/expense_sort_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<ExpenseSortBy>> openMenu(WidgetTester tester) async {
    final selections = <ExpenseSortBy>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ExpenseSortMenu.show(
                context: context,
                current: ExpenseSortBy.dateDesc,
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

  testWidgets('lists every option in a single list section', (tester) async {
    await openMenu(tester);

    expect(find.byType(FrostedListSection), findsOneWidget);
    for (final option in ExpenseSortBy.values) {
      expect(find.text(option.label), findsOneWidget);
    }
  });

  testWidgets('closes on a selection and reports the option', (tester) async {
    final selections = await openMenu(tester);

    await tester.tap(find.text(ExpenseSortBy.amountDesc.label));
    await tester.pumpAndSettle();

    expect(selections, [ExpenseSortBy.amountDesc]);
    expect(find.byType(FrostedListSection), findsNothing);
  });
}
