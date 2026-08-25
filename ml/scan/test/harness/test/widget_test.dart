import 'package:flutter_test/flutter_test.dart';

import 'package:ocr_harness/gallery_screen.dart';
import 'package:ocr_harness/main.dart';
import 'package:ocr_harness/session_stats.dart';
import 'package:ocr_harness/stats_screen.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'session_stats_test.dart' show resultWith;

void main() {
  testWidgets('home offers the three bench modes', (WidgetTester tester) async {
    await tester.pumpWidget(const OcrHarnessApp());

    expect(find.text('Suite complète'), findsOneWidget);
    expect(find.text('Tester depuis la galerie'), findsOneWidget);
    expect(find.text('Scanner un ticket'), findsOneWidget);
    expect(find.text('Stats de session'), findsOneWidget);
  });

  testWidgets('stats screen opens from home and starts empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OcrHarnessApp());
    await tester.tap(find.text('Stats de session'));
    await tester.pumpAndSettle();

    expect(find.byType(StatsScreen), findsOneWidget);
    expect(find.text('Aucun ticket traité pour l\'instant.'), findsOneWidget);
  });

  testWidgets('gallery screen starts empty with a picker button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OcrHarnessApp());
    await tester.tap(find.text('Tester depuis la galerie'));
    await tester.pumpAndSettle();

    expect(find.byType(GalleryScreen), findsOneWidget);
    expect(
      find.text('Choisis des photos de tickets à tester.'),
      findsOneWidget,
    );
    expect(find.text('Choisir'), findsOneWidget);
  });

  testWidgets('stats screen updates live while tickets are recorded', (
    WidgetTester tester,
  ) async {
    sessionStats.reset();
    await tester.pumpWidget(const OcrHarnessApp());
    await tester.tap(find.text('Stats de session'));
    await tester.pumpAndSettle();

    sessionStats.record(resultWith(FlowStage.local));
    await tester.pump();
    expect(find.text('Vérifiés : 1/1 (100.0 %)'), findsOneWidget);

    sessionStats.record(resultWith(FlowStage.confirm, retry: true));
    await tester.pump();
    expect(find.text('Vérifiés : 1/2 (50.0 %)'), findsOneWidget);
    sessionStats.reset();
  });
}
