import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Dépenses', () {
    testWidgets('Scenario 5 - Add monthly expense appears in list and dashboard', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createExpense(tester, name: 'Loyer', amount: '800');

      await navigateToTab(tester, 2);
      expect(find.text('Loyer'), findsOneWidget);
      expect(find.textContaining('800'), findsWidgets);

      await navigateToTab(tester, 0);
      expect(find.textContaining('800'), findsWidgets);
    });

    testWidgets('Scenario 6 - Add annual expense shows monthly amount in dashboard', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createExpense(tester, name: 'Assurance Auto', amount: '1200', frequency: 'Annuel');

      await navigateToTab(tester, 0);
      expect(find.textContaining('100'), findsWidgets);
    });

    testWidgets('Scenario 7 - Edit all expense fields', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createExpense(tester, name: 'Loyer', amount: '800');

      await navigateToTab(tester, 2);
      await tester.tap(find.text('Loyer'));
      await tester.pumpAndSettle();

      await clearAndEnterTextField(tester, 'Nom', 'Loyer Modifié');
      await clearAndEnterTextField(tester, 'Montant', '900');
      await scrollDown(tester);
      await tapButton(tester, 'Enregistrer');

      expect(find.text('Loyer Modifié'), findsOneWidget);
      expect(find.textContaining('900'), findsWidgets);
    });

    testWidgets('Scenario 8 - Delete expense disappears and dashboard updates', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createExpense(tester, name: 'Loyer', amount: '800');

      await navigateToTab(tester, 2);
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      await tapButton(tester, 'Supprimer');

      await tapButton(tester, 'Supprimer');

      expect(find.text('Loyer'), findsNothing);
    });

    testWidgets('Scenario 9 - Filter expenses by category', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createExpense(tester, name: 'Loyer', amount: '800');

      await navigateToTab(tester, 2);
      expect(find.text('Loyer'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      await scrollDown(tester, distance: 200);
      await tapButton(tester, 'Logement');
      await tapButton(tester, 'Appliquer');

      expect(find.text('Loyer'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      await scrollDown(tester, distance: 200);
      await tapButton(tester, 'Logement');
      await tapButton(tester, 'Transport');
      await tapButton(tester, 'Appliquer');

      expect(find.text('Loyer'), findsNothing);
    });

    testWidgets('Scenario 10 - Filter expenses by frequency', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');

      await createExpense(tester, name: 'Loyer', amount: '800', frequency: 'Mensuel');
      await createExpense(tester, name: 'Assurance', amount: '1200', frequency: 'Annuel');

      await navigateToTab(tester, 2);
      expect(find.text('Loyer'), findsOneWidget);
      expect(find.text('Assurance'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      await tapButton(tester, 'Mensuel');
      await tapButton(tester, 'Appliquer');

      expect(find.text('Loyer'), findsOneWidget);
      expect(find.text('Assurance'), findsNothing);
    });
  });
}
