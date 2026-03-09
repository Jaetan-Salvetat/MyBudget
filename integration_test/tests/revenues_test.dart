import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Revenus', () {
    testWidgets('Scenario 11 - Add regular revenue appears in list and dashboard', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createRevenue(tester, name: 'Salaire', amount: '2000');

      await navigateToTab(tester, 3);
      expect(find.text('Salaire'), findsOneWidget);
      expect(find.textContaining('2'), findsWidgets);

      await navigateToTab(tester, 0);
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('Scenario 13 - Edit all revenue fields', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createRevenue(tester, name: 'Salaire', amount: '2000');

      await navigateToTab(tester, 3);
      await tester.tap(find.text('Salaire'));
      await tester.pumpAndSettle();

      await clearAndEnterTextField(tester, 'Nom', 'Salaire Net');
      await clearAndEnterTextField(tester, 'Montant', '2200');
      await scrollDown(tester);
      await tapButton(tester, 'Enregistrer');

      expect(find.text('Salaire Net'), findsOneWidget);
      expect(find.textContaining('200'), findsWidgets);
    });

    testWidgets('Scenario 14 - Delete revenue disappears', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createRevenue(tester, name: 'Salaire', amount: '2000');

      await navigateToTab(tester, 3);
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      await tapButton(tester, 'Supprimer');
      await tapButton(tester, 'Supprimer');

      expect(find.text('Salaire'), findsNothing);
    });
  });
}
