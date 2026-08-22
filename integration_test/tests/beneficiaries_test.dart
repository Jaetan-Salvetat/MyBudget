import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Bénéficiaires', () {
    testWidgets('Scenario 19 - Create beneficiary appears in list', (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les bénéficiaires');
      await tapButton(tester, 'Bénéficiaire');
      await enterTextField(tester, 'Nom', 'Propriétaire');
      await tapButton(tester, 'Ajouter');

      expect(find.text('Propriétaire'), findsOneWidget);
    });

    testWidgets('Scenario 20 - Delete beneficiary without linked transactions', (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await tapButton(tester, 'Gérer les bénéficiaires');
      await tapButton(tester, 'Bénéficiaire');
      await enterTextField(tester, 'Nom', 'Temporaire');
      await tapButton(tester, 'Ajouter');

      expect(find.text('Temporaire'), findsOneWidget);

      await tester.tap(find.byIcon(Symbols.delete_rounded).first);
      await tester.pumpAndSettle();

      await tapButton(tester, 'Supprimer');

      expect(find.text('Temporaire'), findsNothing);
    });

  });
}
