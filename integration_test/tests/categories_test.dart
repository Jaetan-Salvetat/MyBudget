import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Catégories', () {
    testWidgets('Scenario 15 - Create category appears in list', (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');
      await tapButton(tester, 'Ajouter une catégorie');
      await enterTextField(tester, 'Nom de la catégorie', 'Transport');
      await tapButton(tester, 'Ajouter');

      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('Scenario 16 - Edit category', (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');
      await tapButton(tester, 'Ajouter une catégorie');
      await enterTextField(tester, 'Nom de la catégorie', 'Transport');
      await tapButton(tester, 'Ajouter');

      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();

      await clearAndEnterTextField(tester, 'Nom de la catégorie', 'Mobilité');
      await tapButton(tester, 'Enregistrer');

      expect(find.text('Mobilité'), findsOneWidget);
      expect(find.text('Transport'), findsNothing);
    });

    testWidgets('Scenario 17 - Delete category without linked expenses', (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');
      await tapButton(tester, 'Ajouter une catégorie');
      await enterTextField(tester, 'Nom de la catégorie', 'Temporaire');
      await tapButton(tester, 'Ajouter');

      expect(find.text('Temporaire'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      await tapButton(tester, 'Supprimer');

      expect(find.text('Temporaire'), findsNothing);
    });

    testWidgets('Scenario 18 - Delete category with linked expenses is blocked', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createCategory(tester, 'Logement');
      await createExpense(tester, name: 'Loyer', amount: '800');

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('impossible'), findsOneWidget);
      await tapButton(tester, 'Compris');

      expect(find.text('Logement'), findsOneWidget);
    });
  });
}
