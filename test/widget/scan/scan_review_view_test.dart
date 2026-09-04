import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/scan/scan_formats.dart';
import 'package:mybudget/ui/scan/widgets/scan_item_list.dart';
import 'package:mybudget/ui/scan/widgets/scan_output_summary.dart';
import 'package:mybudget/ui/scan/widgets/scan_item_row.dart';
import 'package:mybudget/ui/scan/widgets/scan_receipt_header.dart';
import 'package:mybudget/ui/scan/widgets/scan_reveal.dart';
import 'package:mybudget/ui/scan/widgets/scan_review_view.dart';

import '../../helpers/scan_review_factory.dart';

ReceiptScanResultModel receipt({double? printedTotal}) {
  return scanResult(
    printedTotal: printedTotal,
    items: [
      scannedItem(name: 'Pain complet', amount: 2.0),
      scannedItem(
        name: 'Lessive liquide',
        amount: 8.90,
        discount: 1.50,
        slug: 'maison.entretien',
      ),
      scannedItem(name: 'Piles LR6', amount: 5.49, slug: null, confidence: 0),
    ],
  );
}

Future<void> pumpReview(
  WidgetTester tester,
  ReceiptScanResultModel result, {
  double reveal = 1,
  void Function(int index)? onPickCategory,
  void Function(String store)? onStoreChanged,
  VoidCallback? onFillGap,
  VoidCallback? onFocusPending,
}) async {
  await tester.pumpWidget(
    scanHarness(
      ScanReviewView(
        result: result,
        resolve: resolveCategory,
        reveal: AlwaysStoppedAnimation<double>(reveal),
        onStoreChanged: onStoreChanged ?? (_) {},
        onPickDate: () {},
        onFillGap: onFillGap ?? () {},
        onFocusPending: onFocusPending ?? () {},
        onPickCategory: onPickCategory ?? (_) {},
        onNameChanged: (_, _) {},
        onAmountChanged: (_, _) {},
        onRemove: (_) {},
      ),
    ),
  );
  await tester.pump();
}

double rowEntranceOf(WidgetTester tester) {
  return tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byType(ScanItemRow).first,
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;
}

Finder eyebrow(String text) => find.text(text.toUpperCase());

Future<void> scrollToSummary(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('l\'en-tête porte l\'enseigne et le total des articles', (
    tester,
  ) async {
    await pumpReview(tester, receipt());

    expect(find.text('Carrefour Market'), findsOneWidget);
    expect(find.textContaining('14,89'), findsWidgets);
  });

  testWidgets('sans total imprimé, aucune garantie n\'est annoncée', (
    tester,
  ) async {
    await pumpReview(tester, receipt());

    expect(find.text(ScanReceiptHeader.verifiedLabel), findsNothing);
    expect(find.textContaining('écart'), findsNothing);
  });

  testWidgets('une somme qui tombe juste annonce des montants vérifiés', (
    tester,
  ) async {
    await pumpReview(tester, receipt(printedTotal: 14.89));

    expect(find.text(ScanReceiptHeader.verifiedLabel), findsOneWidget);
  });

  testWidgets('une somme qui ne tombe pas affiche l\'écart', (tester) async {
    await pumpReview(tester, receipt(printedTotal: 16.64));

    expect(find.textContaining('1,75'), findsWidgets);
  });

  testWidgets('l\'écart propose d\'ajouter la ligne manquante', (tester) async {
    var asked = 0;
    await pumpReview(
      tester,
      receipt(printedTotal: 16.64),
      onFillGap: () => asked++,
    );

    await tester.tap(find.textContaining('écart'));
    await tester.pump();

    expect(asked, 1);
  });

  testWidgets('l\'en-tête de liste compte ce qui reste à confirmer', (
    tester,
  ) async {
    await pumpReview(tester, receipt());

    expect(find.text('1 à confirmer'), findsOneWidget);
    expect(find.text(ScanItemList.allConfirmedLabel), findsNothing);
  });

  testWidgets('tout confirmé, l\'en-tête de liste le dit', (tester) async {
    final result = scanResult(
      items: [scannedItem(confirmed: true), scannedItem(confirmed: true)],
    );
    await pumpReview(tester, result);

    expect(find.text(ScanItemList.allConfirmedLabel), findsOneWidget);
  });

  testWidgets('toucher le compteur remonte la demande de recentrage', (
    tester,
  ) async {
    var focused = 0;
    await pumpReview(tester, receipt(), onFocusPending: () => focused++);

    await tester.tap(find.text('1 à confirmer'));
    await tester.pump();

    expect(focused, 1);
  });

  testWidgets('le bloc de sortie annonce les dépenses à créer', (tester) async {
    await pumpReview(tester, receipt());
    await scrollToSummary(tester);

    expect(eyebrow(ScanOutputSummary.titleOf(2)), findsOneWidget);
    expect(find.text('Boulangerie'), findsWidgets);
    expect(find.text('Entretien'), findsWidgets);
    expect(find.textContaining('7,40'), findsWidgets);
  });

  testWidgets('un article non rangé ne crée aucune dépense', (tester) async {
    final result = scanResult(
      items: [scannedItem(slug: null, confidence: 0)],
    );
    await pumpReview(tester, result);
    await scrollToSummary(tester);

    expect(eyebrow(ScanOutputSummary.titleOf(0)), findsOneWidget);
  });

  testWidgets('l\'écran replié ne montre encore aucune ligne', (tester) async {
    await pumpReview(tester, receipt(), reveal: 0);

    expect(rowEntranceOf(tester), 0);
  });

  testWidgets('la liste attend que le montant soit monté', (tester) async {
    await pumpReview(tester, receipt(), reveal: ScanReveal.listStart);

    expect(rowEntranceOf(tester), 0);
  });

  testWidgets('déplié, les lignes sont posées', (tester) async {
    await pumpReview(tester, receipt());

    expect(rowEntranceOf(tester), 1);
  });

  testWidgets('une date non lue devient la date du jour', (tester) async {
    final result = ReceiptScanResultModel(
      storeName: 'Carrefour Market',
      items: [scannedItem()],
    );
    await pumpReview(tester, result);

    expect(
      find.descendant(
        of: find.byType(ScanReceiptHeader),
        matching: find.text(scanDate.format(DateTime.now())),
      ),
      findsOneWidget,
    );
  });

  testWidgets('la ligne d\'information part du bord du contenu', (
    tester,
  ) async {
    await pumpReview(tester, receipt(printedTotal: 14.89));

    final date = find.descendant(
      of: find.byType(ScanReceiptHeader),
      matching: find.text(scanDate.format(DateTime(2026, 8, 31))),
    );

    expect(tester.getTopLeft(date).dx, FrostedSpacing.sp5);
  });

  testWidgets('les montants du récapitulatif s\'alignent sur les articles', (
    tester,
  ) async {
    await pumpReview(tester, receipt());
    await scrollToSummary(tester);

    final itemAmount = find
        .descendant(
          of: find.byType(ScanItemRow).first,
          matching: find.byType(TextField),
        )
        .last;
    final groupAmount = find.descendant(
      of: find.byType(ScanOutputSummary),
      matching: find.textContaining('7,40'),
    );

    expect(
      tester.getTopRight(groupAmount).dx,
      tester.getTopRight(itemAmount).dx,
    );
  });

  testWidgets('une date lue reste une date', (tester) async {
    await pumpReview(tester, receipt());

    expect(
      find.descendant(
        of: find.byType(ScanReceiptHeader),
        matching: find.textContaining('31 août'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('corriger l\'enseigne remonte le libellé', (tester) async {
    String? received;
    await pumpReview(tester, receipt(), onStoreChanged: (v) => received = v);

    await tester.enterText(find.byType(TextField).first, 'Monoprix');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(received, 'Monoprix');
  });
}
