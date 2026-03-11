import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Comptes', () {
    testWidgets('Scenario 1 - Create account appears in list', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Courant', 'BNP Paribas');

      await navigateToTab(tester, 1);
      expect(find.text('Compte Courant'), findsOneWidget);
    });

    testWidgets('Scenario 2 - Edit account name and bank', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Courant', 'BNP');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte Courant'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await clearAndEnterTextField(tester, 'Nom du compte', 'Compte Joint');
      await enterAutocompleteField(tester, 'Nom de la banque', 'Societe Generale');
      await tapButton(tester, 'Enregistrer');

      expect(find.text('Compte Joint'), findsOneWidget);
    });

    testWidgets('Scenario 3 - Delete account without linked entities', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Temp', 'BNP');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte Temp'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tapButton(tester, 'Supprimer');

      expect(find.text('Compte Temp'), findsNothing);
    });

    testWidgets('Scenario 4 - Delete account with linked entities is blocked', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Lié', 'BNP');
      await createCategory(tester, 'Logement');
      await createExpense(tester, name: 'Loyer', amount: '800');

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte Lié'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.textContaining('impossible'), findsOneWidget);
    });
  });
}
