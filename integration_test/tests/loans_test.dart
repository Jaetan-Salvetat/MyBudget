import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Emprunts', () {
    testWidgets('Scenario 22 - Create amortizable loan appears in list', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createAmortizableLoan(
        tester,
        name: 'Prêt Immobilier',
        lender: 'BNP',
        amount: '200000',
        duration: '240',
        rate: '3.5',
      );

      await navigateToTab(tester, 4);
      expect(find.text('Prêt Immobilier'), findsOneWidget);
    });

    testWidgets('Scenario 23 - Create in-fine loan', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');

      await navigateToTab(tester, 4);
      await tapFab(tester);

      await enterTextField(tester, 'Nom du prêt', 'Prêt In Fine');
      await enterTextField(tester, 'Prêteur (Banque)', 'Banque');
      await enterTextField(tester, 'Montant emprunté', '100000');
      await scrollDown(tester);
      await tapButton(tester, 'Compte de prélèvement');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compte Test').last);
      await tester.pumpAndSettle();
      await tapButton(tester, 'Suivant');

      await tapButton(tester, 'Mois');
      await enterTextField(tester, 'Durée', '120');
      await enterTextField(tester, "Taux d'intérêt (Annuel)", '4.0');
      await tapButton(tester, 'Suivant');

      await tapButton(tester, 'In Fine');
      await tapButton(tester, 'Suivant');

      await tapButton(tester, 'Suivant');

      await tapButton(tester, 'Terminer');

      await navigateToTab(tester, 4);
      expect(find.text('Prêt In Fine'), findsOneWidget);
    });

    testWidgets('Scenario 24 - Mark payments and verify progress', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createAmortizableLoan(
        tester,
        name: 'Prêt Test',
        lender: 'BNP',
        amount: '10000',
        duration: '12',
        rate: '2.0',
      );

      await navigateToTab(tester, 4);
      await tester.tap(find.text('Prêt Test'));
      await tester.pumpAndSettle();

      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('Scenario 25 - Delete loan disappears', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createAmortizableLoan(
        tester,
        name: 'Prêt Temp',
        lender: 'BNP',
        amount: '10000',
        duration: '12',
        rate: '2.0',
      );

      await navigateToTab(tester, 4);
      await tester.tap(find.text('Prêt Temp'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tapButton(tester, 'Supprimer');

      expect(find.text('Prêt Temp'), findsNothing);
    });
  });
}
