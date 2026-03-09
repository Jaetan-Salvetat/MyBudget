import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('E2E', () {
    testWidgets('Scenario 32 - Full CRUD flow', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Courant', 'BNP');
      await navigateToTab(tester, 1);
      expect(find.text('Compte Courant'), findsOneWidget);

      await createCategory(tester, 'Logement');

      await createExpense(tester, name: 'Loyer', amount: '800');
      await navigateToTab(tester, 2);
      expect(find.text('Loyer'), findsOneWidget);

      await navigateToTab(tester, 0);
      expect(find.textContaining('800'), findsWidgets);

      await navigateToTab(tester, 2);
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tapButton(tester, 'Supprimer');
      await tapButton(tester, 'Supprimer');
      expect(find.text('Loyer'), findsNothing);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();
      await tapButton(tester, 'Supprimer');
      expect(find.text('Logement'), findsNothing);
      await dismissBottomSheet(tester);
      await goBack(tester);

      await navigateToTab(tester, 1);
      await tester.tap(find.text('Compte Courant'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Supprimer');

      expect(find.text('Compte Courant'), findsNothing);
    });
  });
}
