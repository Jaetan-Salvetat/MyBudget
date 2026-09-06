import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/common/widgets/transaction_actions_sheet.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => TransactionActionsSheet.show(
                context: context,
                deleteConfirmationMessage: 'Supprimer cette dépense ?',
                onEdit: onEdit,
                onDelete: (_) => onDelete(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('groups the actions in a single list section', (tester) async {
    await openSheet(tester, onEdit: () {}, onDelete: () {});

    final section = tester.widget<FrostedListSection>(
      find.byType(FrostedListSection),
    );

    expect(section.tiles, hasLength(2));
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });

  testWidgets('closes and edits when Modifier is tapped', (tester) async {
    var edited = false;
    await openSheet(tester, onEdit: () => edited = true, onDelete: () {});

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
    expect(find.byType(FrostedBottomSheet), findsNothing);
  });

  testWidgets('keeps the transaction when the deletion is cancelled', (
    tester,
  ) async {
    var deleted = false;
    await openSheet(tester, onEdit: () {}, onDelete: () => deleted = true);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette dépense ?'), findsOneWidget);
    expect(deleted, isFalse);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(find.byType(FrostedDialog), findsNothing);
  });

  testWidgets('deletes once the confirmation is accepted', (tester) async {
    var deleted = false;
    await openSheet(tester, onEdit: () {}, onDelete: () => deleted = true);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FrostedButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });
}
