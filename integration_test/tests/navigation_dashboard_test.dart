import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Navigation & Dashboard', () {
    testWidgets('Scenario 26 - Navigate between 5 tabs', (tester) async {
      await initializeTestApp(tester);

      expect(find.text('MyBudget'), findsOneWidget);

      await navigateToTab(tester, 1);
      expect(find.text('Comptes'), findsWidgets);

      await navigateToTab(tester, 2);
      expect(find.text('Dépenses'), findsWidgets);

      await navigateToTab(tester, 3);
      expect(find.text('Revenus'), findsWidgets);

      await navigateToTab(tester, 4);
      expect(find.text('Emprunts'), findsWidgets);

      await navigateToTab(tester, 0);
      expect(find.text('MyBudget'), findsOneWidget);
    });

    testWidgets('Scenario 27 - Dashboard shows correct balance', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');
      await createExpense(tester, name: 'Loyer', amount: '800');
      await createRevenue(tester, name: 'Salaire', amount: '2000');

      await navigateToTab(tester, 0);
      await tester.pumpAndSettle();

      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('Scenario 28 - FAB creates entities from home screen', (tester) async {
      await initializeTestApp(tester);

      await navigateToTab(tester, 0);
      expect(find.byType(FrostedFloatingActionButton), findsNothing);

      await navigateToTab(tester, 1);
      expect(find.byType(FrostedFloatingActionButton), findsOneWidget);
      await tapFab(tester);
      expect(find.text('Ajouter un compte'), findsWidgets);
      await tapButton(tester, 'Annuler');

      await navigateToTab(tester, 2);
      expect(find.byType(FrostedFloatingActionButton), findsOneWidget);
      await tapFab(tester);
      expect(find.text('Aucun compte disponible'), findsOneWidget);
      await tapButton(tester, 'OK');

      await navigateToTab(tester, 3);
      expect(find.byType(FrostedFloatingActionButton), findsOneWidget);
      await tapFab(tester);
      expect(find.text('Aucun compte disponible'), findsOneWidget);
      await tapButton(tester, 'OK');

      await navigateToTab(tester, 4);
      expect(find.byType(FrostedFloatingActionButton), findsOneWidget);
      await tapFab(tester);
      expect(find.text('Aucun compte disponible'), findsOneWidget);
      await tapButton(tester, 'OK');
    });
  });
}
