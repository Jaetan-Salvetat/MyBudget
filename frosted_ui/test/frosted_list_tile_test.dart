import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

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

  Color? fillOf(WidgetTester tester) {
    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(FrostedListTile),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    return (container.decoration! as BoxDecoration).color;
  }

  Future<ColorScheme> pumpTile(
    WidgetTester tester,
    FrostedListTile tile,
  ) async {
    late ColorScheme scheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              scheme = Theme.of(context).colorScheme;
              return tile;
            },
          ),
        ),
      ),
    );
    return scheme;
  }

  testWidgets('a filled tile paints its own container surface', (
    WidgetTester tester,
  ) async {
    final ColorScheme scheme = await pumpTile(
      tester,
      const FrostedListTile(title: 'Alimentation'),
    );

    expect(fillOf(tester), scheme.surfaceContainer);
  });

  testWidgets('a plain tile paints no surface of its own', (
    WidgetTester tester,
  ) async {
    await pumpTile(
      tester,
      const FrostedListTile(
        title: 'Alimentation',
        variant: FrostedListTileVariant.plain,
      ),
    );

    expect(fillOf(tester), Colors.transparent);
  });

  testWidgets('a selected plain tile still carries the selection fill', (
    WidgetTester tester,
  ) async {
    final ColorScheme scheme = await pumpTile(
      tester,
      const FrostedListTile(
        title: 'Alimentation',
        variant: FrostedListTileVariant.plain,
        selected: true,
      ),
    );

    expect(fillOf(tester), scheme.secondaryContainer);
  });

  testWidgets('a pressed plain tile shows a state layer over the background', (
    WidgetTester tester,
  ) async {
    final ColorScheme scheme = await pumpTile(
      tester,
      FrostedListTile(
        title: 'Alimentation',
        variant: FrostedListTileVariant.plain,
        onTap: () {},
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Alimentation')),
    );
    await tester.pumpAndSettle();

    expect(fillOf(tester), isNot(Colors.transparent));
    expect(fillOf(tester)!.a, greaterThan(0));
    expect(fillOf(tester), isNot(scheme.surfaceContainer));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  test('a section keeps the variant when it assigns a position', () {
    const FrostedListTile tile = FrostedListTile(
      title: 'Alimentation',
      variant: FrostedListTileVariant.plain,
    );

    expect(
      tile.withPosition(FrostedTilePosition.first).variant,
      FrostedListTileVariant.plain,
    );
  });
}
