import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Virements', () {
    testWidgets('Scenario 33 - Create transfer visible in transfer list', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte A', 'BNP');
      await createAccount(tester, 'Compte B', 'BNP');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte A'));
      await tester.pumpAndSettle();

      await createTransferFromAccountDetails(
        tester,
        name: 'Virement épargne',
        amount: '500',
        destinationAccount: 'Compte B',
      );

      expect(find.text('Virement épargne'), findsOneWidget);
    });

    testWidgets('Scenario 34 - Transfer visible in both accounts with direction', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte A', 'BNP');
      await createAccount(tester, 'Compte B', 'BNP');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte A'));
      await tester.pumpAndSettle();

      await createTransferFromAccountDetails(
        tester,
        name: 'Virement test',
        amount: '300',
        destinationAccount: 'Compte B',
      );

      expect(find.textContaining('Vers Compte B'), findsOneWidget);

      await goBack(tester);
      await tester.tap(find.text('Compte B'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Depuis Compte A'), findsOneWidget);
    });

    testWidgets('Scenario 35 - Edit transfer via more_vert', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte A', 'BNP');
      await createAccount(tester, 'Compte B', 'BNP');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte A'));
      await tester.pumpAndSettle();

      await createTransferFromAccountDetails(
        tester,
        name: 'Virement initial',
        amount: '500',
        destinationAccount: 'Compte B',
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tapButton(tester, 'Modifier');

      await clearAndEnterTextField(tester, 'Nom', 'Virement modifié');
      await clearAndEnterTextField(tester, 'Montant', '750');
      await scrollDown(tester);
      await tapButton(tester, 'Enregistrer');

      expect(find.text('Virement modifié'), findsOneWidget);
      expect(find.text('Virement initial'), findsNothing);
    });

    testWidgets('Scenario 36 - Delete transfer via more_vert', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte A', 'BNP');
      await createAccount(tester, 'Compte B', 'BNP');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte A'));
      await tester.pumpAndSettle();

      await createTransferFromAccountDetails(
        tester,
        name: 'Virement à supprimer',
        amount: '200',
        destinationAccount: 'Compte B',
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tapButton(tester, 'Supprimer');
      await tapButton(tester, 'Supprimer');

      expect(find.text('Virement à supprimer'), findsNothing);
    });

    testWidgets('Scenario 37 - Account with linked transfer cannot be deleted', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte A', 'BNP');
      await createAccount(tester, 'Compte B', 'BNP');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte A'));
      await tester.pumpAndSettle();

      await createTransferFromAccountDetails(
        tester,
        name: 'Virement bloquant',
        amount: '100',
        destinationAccount: 'Compte B',
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.textContaining('impossible'), findsOneWidget);
    });

    testWidgets('Scenario 38 - Hero card shows Virements stat', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte A', 'BNP');
      await createAccount(tester, 'Compte B', 'BNP');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte A'));
      await tester.pumpAndSettle();

      await createTransferFromAccountDetails(
        tester,
        name: 'Virement hero',
        amount: '100',
        destinationAccount: 'Compte B',
      );

      expect(find.text('Virements'), findsWidgets);
    });
  });
}
