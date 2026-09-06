import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget tile) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: const Color(0xFF6750A4)),
        home: Scaffold(body: SingleChildScrollView(child: tile)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uncontrolled tile toggles its own body', (tester) async {
    await pump(
      tester,
      const FrostedExpansionTile(title: 'Dépenses', child: Text('body')),
    );

    expect(find.text('body'), findsNothing);

    await tester.tap(find.text('Dépenses'));
    await tester.pumpAndSettle();

    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('a controlled tile follows its expanded flag, not the tap', (
    tester,
  ) async {
    bool? requested;

    await pump(
      tester,
      FrostedExpansionTile(
        title: 'Dépenses',
        expanded: false,
        onExpansionChanged: (value) => requested = value,
        child: const Text('body'),
      ),
    );

    await tester.tap(find.text('Dépenses'));
    await tester.pumpAndSettle();

    expect(requested, isTrue);
    expect(find.text('body'), findsNothing);
  });

  testWidgets('a controlled tile opens when its flag turns true', (
    tester,
  ) async {
    await pump(
      tester,
      const FrostedExpansionTile(
        title: 'Dépenses',
        expanded: true,
        child: Text('body'),
      ),
    );

    expect(find.text('body'), findsOneWidget);
  });
}
