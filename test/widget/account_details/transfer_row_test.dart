import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/data/model/transfer_model.dart';
import 'package:mybudget/ui/account_details/widgets/transfer_row.dart';

void main() {
  TransferModel transfer() => TransferModel.create(
    name: 'Épargne',
    amount: 150,
    fromAccountId: 1,
    toAccountId: 2,
    startDate: DateTime(2026, 1, 5),
    frequency: Frequency.monthly,
  );

  Future<void> pumpRow(
    WidgetTester tester, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TransferRow(
            transfer: transfer(),
            currentAccountId: 1,
            otherAccountName: 'Livret A',
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }

  testWidgets('opens the actions sheet from the trailing button', (
    tester,
  ) async {
    await pumpRow(tester, onEdit: () {}, onDelete: () {});

    await tester.tap(find.byIcon(Symbols.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(FrostedListSection), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });

  testWidgets('edits when the row itself is tapped', (tester) async {
    var edited = false;
    await pumpRow(tester, onEdit: () => edited = true, onDelete: () {});

    await tester.tap(find.text('Vers Livret A'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
  });

  testWidgets('deletes once the confirmation is accepted', (tester) async {
    var deleted = false;
    await pumpRow(tester, onEdit: () {}, onDelete: () => deleted = true);

    await tester.tap(find.byIcon(Symbols.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Voulez-vous vraiment supprimer ce virement ?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FrostedButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });
}
