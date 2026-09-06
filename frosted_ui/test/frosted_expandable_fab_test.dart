import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<void> pump(
    WidgetTester tester, {
    required List<FrostedFabAction> actions,
    GlobalKey<FrostedExpandableFabState>? fabKey,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(
          floatingActionButton: FrostedExpandableFab(
            key: fabKey,
            actions: actions,
          ),
        ),
      ),
    );
  }

  List<FrostedFabAction> actionsRecording(List<String> log) {
    return <FrostedFabAction>[
      FrostedFabAction(
        icon: Icons.upload,
        label: 'Revenu',
        onPressed: () => log.add('revenu'),
      ),
      FrostedFabAction(
        icon: Icons.download,
        label: 'Dépense',
        onPressed: () => log.add('depense'),
      ),
    ];
  }

  group('FrostedExpandableFab', () {
    testWidgets('starts closed, showing only the trigger', (
      WidgetTester tester,
    ) async {
      await pump(tester, actions: actionsRecording(<String>[]));

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.upload), findsNothing);
      expect(find.byIcon(Icons.download), findsNothing);
    });

    testWidgets('reveals every action on tap', (WidgetTester tester) async {
      await pump(tester, actions: actionsRecording(<String>[]));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.upload), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.text('Revenu'), findsOneWidget);
      expect(find.text('Dépense'), findsOneWidget);
    });

    testWidgets('swaps the trigger glyph while open', (
      WidgetTester tester,
    ) async {
      await pump(tester, actions: actionsRecording(<String>[]));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('stacks the actions above the trigger', (
      WidgetTester tester,
    ) async {
      await pump(tester, actions: actionsRecording(<String>[]));
      final double triggerTop = tester.getTopLeft(find.byIcon(Icons.add)).dy;

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(
        tester.getBottomLeft(find.byIcon(Icons.download)).dy,
        lessThan(triggerTop),
      );
      expect(
        tester.getBottomLeft(find.byIcon(Icons.upload)).dy,
        lessThan(tester.getTopLeft(find.byIcon(Icons.download)).dy),
      );
    });

    testWidgets('runs the action and closes on tap', (
      WidgetTester tester,
    ) async {
      final List<String> log = <String>[];
      await pump(tester, actions: actionsRecording(log));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      expect(log, <String>['depense']);
      expect(find.byIcon(Icons.download), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('closes on a scrim tap without running an action', (
      WidgetTester tester,
    ) async {
      final List<String> log = <String>[];
      await pump(tester, actions: actionsRecording(log));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(log, isEmpty);
      expect(find.byIcon(Icons.upload), findsNothing);
    });

    testWidgets('exposes open, close and toggle through its state', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FrostedExpandableFabState> key =
          GlobalKey<FrostedExpandableFabState>();
      await pump(tester, actions: actionsRecording(<String>[]), fabKey: key);

      key.currentState!.open();
      await tester.pumpAndSettle();
      expect(key.currentState!.isOpen, isTrue);
      expect(find.byIcon(Icons.upload), findsOneWidget);

      key.currentState!.toggle();
      await tester.pumpAndSettle();
      expect(key.currentState!.isOpen, isFalse);
      expect(find.byIcon(Icons.upload), findsNothing);

      key.currentState!.open();
      await tester.pumpAndSettle();
      key.currentState!.close();
      await tester.pumpAndSettle();
      expect(key.currentState!.isOpen, isFalse);
    });

    testWidgets('renders unlabelled actions', (WidgetTester tester) async {
      await pump(
        tester,
        actions: <FrostedFabAction>[
          FrostedFabAction(icon: Icons.upload, onPressed: () {}),
        ],
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.upload), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('drops its overlay when disposed while open', (
      WidgetTester tester,
    ) async {
      await pump(tester, actions: actionsRecording(<String>[]));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.dark(seedColor: seed),
          home: const Scaffold(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.upload), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
