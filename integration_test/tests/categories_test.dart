import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Catégories', () {
    testWidgets('Scenario 15 - Taxonomy groups are listed', (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');

      expect(find.text('Alimentation'), findsOneWidget);
      expect(find.text('Restauration'), findsOneWidget);
      expect(find.text('Voyages'), findsOneWidget);
    });

    testWidgets('Scenario 16 - A group reveals its subcategories',
        (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');
      await tapButton(tester, 'Restauration');

      expect(find.text('Restaurant'), findsOneWidget);
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Livraison'), findsOneWidget);
    });

    testWidgets('Scenario 17 - Renaming a subcategory keeps its slug',
        (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');
      await tester.enterText(find.byType(TextField).first, 'Restaurant');
      await tester.pumpAndSettle();
      await tapTooltip(tester, 'Personnaliser', index: 1);

      await clearAndEnterTextField(tester, 'Nom de la catégorie', 'Bistrot');
      await tapButton(tester, 'Enregistrer');

      expect(find.text('Bistrot'), findsOneWidget);
      expect(find.text('Restaurant'), findsNothing);
    });

    testWidgets('Scenario 18 - Categories cannot be created or deleted',
        (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les catégories');

      expect(find.text('Ajouter une catégorie'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
    });
  });
}
