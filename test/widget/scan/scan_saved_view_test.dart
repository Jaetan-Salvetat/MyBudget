import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/scan/widgets/scan_saved_view.dart';

import '../../helpers/scan_review_factory.dart';

Future<void> pumpSaved(
  ft.WidgetTester tester, {
  VoidCallback? onDone,
  VoidCallback? onDiscard,
}) async {
  await tester.pumpWidget(
    scanHarness(
      ScanSavedView(
        result: scanResult(
          items: [
            scannedItem(name: 'Pain complet', amount: 2.0),
            scannedItem(
              name: 'Lessive',
              amount: 8.90,
              discount: 1.50,
              slug: 'maison.entretien',
            ),
          ],
        ),
        resolve: resolveCategory,
        onDone: onDone ?? () {},
        onDiscard: onDiscard ?? () {},
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('le récapitulatif reprend les dépenses écrites', (tester) async {
    await pumpSaved(tester);

    expect(find.text(ScanSavedView.titleOf(2)), findsOneWidget);
    expect(find.text('Boulangerie'), findsOneWidget);
    expect(find.text('Entretien'), findsOneWidget);
    expect(find.textContaining('7,40'), findsOneWidget);
  });

  testWidgets('le montant enregistré est celui de la revue', (tester) async {
    await pumpSaved(tester);

    expect(find.textContaining('9,40'), findsOneWidget);
  });

  testWidgets('l\'enseigne et la date sont rappelées', (tester) async {
    await pumpSaved(tester);

    expect(find.textContaining('Carrefour Market'), findsOneWidget);
    expect(find.textContaining('31 août'), findsOneWidget);
  });

  testWidgets('terminer referme l\'écran', (tester) async {
    var done = 0;
    await pumpSaved(tester, onDone: () => done++);

    await tester.tap(find.text(ScanSavedView.doneLabel));
    await tester.pump();

    expect(done, 1);
  });

  testWidgets('annuler propose de défaire ce qui vient d\'être écrit', (
    tester,
  ) async {
    var discarded = 0;
    await pumpSaved(tester, onDiscard: () => discarded++);

    await tester.tap(find.text(ScanSavedView.discardLabel));
    await tester.pump();

    expect(discarded, 1);
  });
}
