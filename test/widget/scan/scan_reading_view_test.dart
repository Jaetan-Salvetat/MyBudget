import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/models/scan_read_progress_model.dart';
import 'package:mybudget/ui/scan/widgets/scan_motion.dart';
import 'package:mybudget/ui/scan/widgets/scan_reading_view.dart';
import 'package:mybudget/ui/scan/widgets/scan_receipt_header.dart';

import '../../helpers/scan_review_factory.dart';

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

Future<void> pumpReading(
  WidgetTester tester,
  ScanReadProgress progress, {
  Duration? advance,
}) async {
  await tester.pumpWidget(
    scanHarness(
      ScanReadingView(
        reveal: const AlwaysStoppedAnimation<double>(0),
        now: _fixedNow,
        progress: progress,
      ),
    ),
  );
  await tester.pump(advance ?? ScanReceiptHeader.arrival);
}

double opacityOf(WidgetTester tester, Finder of) {
  return tester
      .widget<AnimatedOpacity>(
        find.ancestor(of: of, matching: find.byType(AnimatedOpacity)).first,
      )
      .opacity;
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('avant toute lecture, seul le libellé d\'attente est là', (
    tester,
  ) async {
    await pumpReading(tester, const ScanReadProgress());

    expect(find.text('—'), findsOneWidget);
    expect(
      opacityOf(
        tester,
        find.text(ScanReceiptHeader.readingLabel.toUpperCase()),
      ),
      1,
    );
  });

  testWidgets('le total se pose avant le reste', (tester) async {
    await pumpReading(tester, const ScanReadProgress(printedTotal: 51.64));

    expect(find.textContaining('51,64'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('l\'enseigne remplace le libellé d\'attente en arrivant', (
    tester,
  ) async {
    await pumpReading(
      tester,
      const ScanReadProgress(printedTotal: 51.64, storeName: 'Carrefour'),
    );

    expect(find.text('Carrefour'), findsOneWidget);
    expect(
      opacityOf(
        tester,
        find.text(ScanReceiptHeader.readingLabel.toUpperCase()),
      ),
      0,
    );
  });

  testWidgets('la date se pose quand elle tombe', (tester) async {
    await pumpReading(
      tester,
      ScanReadProgress(
        printedTotal: 51.64,
        storeName: 'Carrefour',
        date: DateTime(2026, 8, 31),
      ),
    );

    expect(find.textContaining('31 août'), findsOneWidget);
  });

  testWidgets('changer de date croise les deux libellés', (tester) async {
    await pumpReading(
      tester,
      ScanReadProgress(
        printedTotal: 51.64,
        storeName: 'Carrefour',
        date: DateTime(2026, 8, 31),
      ),
    );

    await pumpReading(
      tester,
      ScanReadProgress(
        printedTotal: 51.64,
        storeName: 'Carrefour',
        date: DateTime(2026, 8, 29),
      ),
      advance: ScanMotion.swap ~/ 2,
    );

    expect(find.textContaining('31 août'), findsOneWidget);
    expect(find.textContaining('29 août'), findsOneWidget);

    await tester.pump(ScanMotion.swap);
    expect(find.textContaining('31 août'), findsNothing);
  });

  testWidgets('pendant la lecture, la date manquante reste cachée', (
    tester,
  ) async {
    await pumpReading(tester, const ScanReadProgress(printedTotal: 51.64));

    expect(
      opacityOf(tester, find.text(DateFormatter.longDate.format(_fixedNow))),
      0,
    );
  });

  testWidgets('aucune garantie n\'est annoncée pendant la lecture', (
    tester,
  ) async {
    await pumpReading(tester, const ScanReadProgress(printedTotal: 51.64));

    expect(find.text(ScanReceiptHeader.verifiedLabel), findsNothing);
    expect(find.textContaining('écart'), findsNothing);
  });
}
