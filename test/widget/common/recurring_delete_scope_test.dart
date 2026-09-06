import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/common/widgets/transaction_actions_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<RecurringDeletion> deletions;

  setUp(() => deletions = []);

  Future<void> openDialog(
    WidgetTester tester, {
    required RecurringDeletion? initialScope,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => TransactionActionsSheet.show(
                context: context,
                deleteConfirmationMessage: 'Supprimer cette dépense ?',
                initialScope: initialScope,
                onEdit: () {},
                onDelete: deletions.add,
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FrostedButton, 'Supprimer').last);
    await tester.pumpAndSettle();
  }

  testWidgets('a one-off is only confirmed, nothing to choose', (tester) async {
    await openDialog(tester, initialScope: null);

    expect(find.byType(FrostedSwitch), findsNothing);
  });

  testWidgets('a rule already honoured this month keeps it by default', (
    tester,
  ) async {
    await openDialog(tester, initialScope: RecurringDeletion.afterThisMonth);

    expect(find.byType(FrostedSwitch), findsOneWidget);
    expect(
      tester.widget<FrostedSwitch>(find.byType(FrostedSwitch)).value,
      isFalse,
    );

    await confirm(tester);

    expect(deletions, [RecurringDeletion.afterThisMonth]);
  });

  testWidgets('a rule whose turn never came drops it by default', (
    tester,
  ) async {
    await openDialog(
      tester,
      initialScope: RecurringDeletion.includingThisMonth,
    );

    expect(
      tester.widget<FrostedSwitch>(find.byType(FrostedSwitch)).value,
      isTrue,
    );

    await confirm(tester);

    expect(deletions, [RecurringDeletion.includingThisMonth]);
  });

  testWidgets('the reader can say otherwise', (tester) async {
    await openDialog(tester, initialScope: RecurringDeletion.afterThisMonth);

    await tester.tap(find.byType(FrostedSwitch));
    await tester.pumpAndSettle();
    await confirm(tester);

    expect(deletions, [RecurringDeletion.includingThisMonth]);
  });

  testWidgets('cancelling deletes nothing', (tester) async {
    await openDialog(tester, initialScope: RecurringDeletion.afterThisMonth);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(deletions, isEmpty);
  });
}
