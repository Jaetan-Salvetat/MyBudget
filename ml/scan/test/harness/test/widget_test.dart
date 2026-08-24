import 'package:flutter_test/flutter_test.dart';

import 'package:ocr_harness/gallery_screen.dart';
import 'package:ocr_harness/main.dart';

void main() {
  testWidgets('home offers the three bench modes', (WidgetTester tester) async {
    await tester.pumpWidget(const OcrHarnessApp());

    expect(find.text('Suite complète'), findsOneWidget);
    expect(find.text('Tester depuis la galerie'), findsOneWidget);
    expect(find.text('Scanner un ticket'), findsOneWidget);
  });

  testWidgets('gallery screen starts empty with a picker button',
      (WidgetTester tester) async {
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
}
