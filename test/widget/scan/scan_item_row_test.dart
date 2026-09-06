import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/data/model/scanned_item_model.dart';
import 'package:mybudget/ui/scan/widgets/scan_item_row.dart';

import '../../helpers/scan_review_factory.dart';

Future<void> pumpRow(
  WidgetTester tester,
  ScannedItemModel item, {
  bool highlighted = false,
  void Function(String name)? onNameChanged,
  void Function(double amount)? onAmountChanged,
  void Function()? onPickCategory,
}) async {
  await tester.pumpWidget(
    scanHarness(
      ScanItemRow(
        item: item,
        category: resolveCategory(item.categorySlug),
        highlighted: highlighted,
        onNameChanged: onNameChanged ?? (_) {},
        onAmountChanged: onAmountChanged ?? (_) {},
        onPickCategory: onPickCategory ?? () {},
      ),
    ),
  );
}

Color? rowBackground(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer).first,
  );
  return (container.decoration as BoxDecoration?)?.color;
}

void main() {
  testWidgets('la catégorie est écrite sous le nom de l\'article', (
    tester,
  ) async {
    await pumpRow(tester, scannedItem());

    expect(find.text('Boulangerie'), findsOneWidget);
  });

  testWidgets('un article non rangé demande à l\'être', (tester) async {
    await pumpRow(tester, scannedItem(slug: null, confidence: 0));

    expect(find.text(ScanItemRow.unrankedLabel), findsOneWidget);
  });

  testWidgets('une catégorie incertaine demande confirmation', (tester) async {
    await pumpRow(tester, scannedItem(confidence: 0.2));

    expect(find.text('Boulangerie · à confirmer'), findsOneWidget);
  });

  testWidgets('une catégorie tranchée par l\'utilisateur le dit', (
    tester,
  ) async {
    await pumpRow(tester, scannedItem(confidence: 0.2, confirmed: true));

    expect(find.text('Boulangerie · confirmé'), findsOneWidget);
  });

  testWidgets('toucher la catégorie ouvre le sélecteur', (tester) async {
    var opened = 0;
    await pumpRow(tester, scannedItem(), onPickCategory: () => opened++);

    await tester.tap(find.text('Boulangerie'));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('la ligne visée par le compteur se signale', (tester) async {
    await pumpRow(tester, scannedItem(), highlighted: true);
    await tester.pump(ScanItemRow.highlightFade);

    expect(rowBackground(tester), isNot(Colors.transparent));
  });

  testWidgets('une ligne ordinaire ne se signale pas', (tester) async {
    await pumpRow(tester, scannedItem());
    await tester.pump(ScanItemRow.highlightFade);

    expect(rowBackground(tester), Colors.transparent);
  });

  testWidgets('le libellé de catégorie se croise au lieu de sauter', (
    tester,
  ) async {
    await pumpRow(tester, scannedItem(confidence: 0.2));
    expect(find.text('Boulangerie · à confirmer'), findsOneWidget);

    await pumpRow(tester, scannedItem(confidence: 0.2, confirmed: true));
    await tester.pump(ScanItemRow.stateChange ~/ 2);

    expect(find.text('Boulangerie · à confirmer'), findsOneWidget);
    expect(find.text('Boulangerie · confirmé'), findsOneWidget);

    await tester.pump(ScanItemRow.stateChange);
    expect(find.text('Boulangerie · à confirmer'), findsNothing);
  });

  testWidgets('le montant affiché est le montant effectif', (tester) async {
    await pumpRow(tester, scannedItem(amount: 8.90, discount: 1.50));

    expect(find.text('7,40'), findsOneWidget);
    expect(find.textContaining('1,50'), findsOneWidget);
  });

  testWidgets('corriger le montant remonte une valeur relue', (tester) async {
    double? received;
    await pumpRow(
      tester,
      scannedItem(amount: 2.0),
      onAmountChanged: (value) => received = value,
    );

    await tester.enterText(find.byType(TextField).last, '3,25');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(received, 3.25);
  });

  testWidgets('un montant illisible ne remonte rien', (tester) async {
    double? received;
    await pumpRow(
      tester,
      scannedItem(),
      onAmountChanged: (value) => received = value,
    );

    await tester.enterText(find.byType(TextField).last, 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(received, isNull);
  });

  testWidgets('corriger le nom remonte le libellé', (tester) async {
    String? received;
    await pumpRow(
      tester,
      scannedItem(),
      onNameChanged: (value) => received = value,
    );

    await tester.enterText(find.byType(TextField).first, 'Pain de campagne');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(received, 'Pain de campagne');
  });
}
