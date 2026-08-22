import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  testWidgets('an interactive trailing widget gets its own taps', (
    WidgetTester tester,
  ) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(
          body: FrostedListTile(
            title: 'Alimentation',
            onTap: () => log.add('tile'),
            trailing: FrostedIconButton.standard(
              icon: Icons.tune,
              onPressed: () => log.add('trailing'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FrostedIconButton));
    await tester.pumpAndSettle();

    expect(log, <String>['trailing']);
  });

  testWidgets('tapping anywhere else still runs the tile handler', (
    WidgetTester tester,
  ) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(
          body: FrostedListTile(
            title: 'Alimentation',
            onTap: () => log.add('tile'),
            trailing: FrostedIconButton.standard(
              icon: Icons.tune,
              onPressed: () => log.add('trailing'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Alimentation'));
    await tester.pumpAndSettle();

    expect(log, <String>['tile']);
  });
}
