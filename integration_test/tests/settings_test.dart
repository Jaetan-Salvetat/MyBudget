import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Settings', () {
    testWidgets('Scenario 30 - Export data', (tester) async {
      await initializeTestApp(tester);

      await createAccount(tester, 'Compte Test', 'BNP');

      await navigateToSettings(tester);
      await scrollDown(tester, distance: 400);

      await tapButton(tester, 'Exporter mes données');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Scenario 31 - Import button is accessible', (tester) async {
      await initializeTestApp(tester);

      await navigateToSettings(tester);
      await scrollDown(tester, distance: 400);

      expect(find.text('Importer mes données'), findsOneWidget);
    });
  });
}
