import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<void> pump(WidgetTester tester, Widget sheet) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(body: sheet),
      ),
    );
  }

  group('FrostedBottomSheet height', () {
    testWidgets('a taller-than-viewport child is capped, not overflowed', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.dark(seedColor: seed),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FrostedBottomSheet(
                title: 'Catégorie',
                child: ListView(
                  shrinkWrap: true,
                  children: List<Widget>.generate(
                    40,
                    (int i) => SizedBox(height: 48, child: Text('row $i')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FrostedBottomSheet)).height,
        lessThanOrEqualTo(600),
      );
    });
  });

  group('FrostedBottomSheet title', () {
    testWidgets('renders the title above the content', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const FrostedBottomSheet(
          title: 'Nouvelle dépense',
          child: Text('contenu'),
        ),
      );

      expect(find.text('Nouvelle dépense'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Nouvelle dépense')).dy,
        lessThan(tester.getTopLeft(find.text('contenu')).dy),
      );
    });

    testWidgets('renders nothing extra without a title', (
      WidgetTester tester,
    ) async {
      await pump(tester, const FrostedBottomSheet(child: Text('contenu')));

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('styles the title with the titleLarge role', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const FrostedBottomSheet(title: 'Titre', child: SizedBox()),
      );

      final Text title = tester.widget<Text>(find.text('Titre'));

      expect(title.style!.fontSize, FrostedTypeScale.titleLarge.fontSize);
      expect(title.style!.fontWeight, FrostedTypeScale.titleLarge.fontWeight);
    });
  });

  Future<void> openSheet(WidgetTester tester, {bool enableDrag = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => showFrostedBottomSheet<void>(
                context: context,
                enableDrag: enableDrag,
                builder: (_) => const FrostedBottomSheet(
                  title: 'Titre',
                  child: SizedBox(height: 240, child: Text('contenu')),
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  group('FrostedBottomSheet surface', () {
    testWidgets('it paints no drop shadow, which the route would clip', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      final BoxDecoration decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(FrostedBottomSheet),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;

      expect(decoration.boxShadow, isNull);
    });
  });

  group('FrostedBottomSheet close button', () {
    testWidgets('a titled sheet gets a close button', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const FrostedBottomSheet(title: 'Titre', child: Text('contenu')),
      );

      expect(
        find.widgetWithIcon(FrostedIconButton, Icons.close),
        findsOneWidget,
      );
    });

    testWidgets('an untitled sheet gets none', (WidgetTester tester) async {
      await pump(tester, const FrostedBottomSheet(child: Text('contenu')));

      expect(find.widgetWithIcon(FrostedIconButton, Icons.close), findsNothing);
    });

    testWidgets('tapping the close button pops the sheet', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.widgetWithIcon(FrostedIconButton, Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(FrostedBottomSheet), findsNothing);
    });
  });

  group('FrostedBottomSheet drag to dismiss', () {
    testWidgets('the backdrop blur fades in step with the finger', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      final double opened = _barrierSigma(tester);
      final double height = tester
          .getSize(find.byType(FrostedBottomSheet))
          .height;
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(FrostedBottomSheet)),
      );
      await gesture.moveBy(const Offset(0, kDragSlopDefault));
      await gesture.moveBy(Offset(0, height / 2));
      await tester.pump();

      expect(_barrierSigma(tester), closeTo(opened / 2, 1));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a downward drag past the midpoint closes the sheet', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      expect(find.byType(FrostedBottomSheet), findsOneWidget);

      await tester.drag(find.byType(FrostedBottomSheet), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byType(FrostedBottomSheet), findsNothing);
    });

    testWidgets('a short drag snaps the sheet back open', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.drag(find.byType(FrostedBottomSheet), const Offset(0, 24));
      await tester.pumpAndSettle();

      expect(find.byType(FrostedBottomSheet), findsOneWidget);
    });

    testWidgets('a fast downward fling closes the sheet', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.fling(
        find.byType(FrostedBottomSheet),
        const Offset(0, 80),
        2000,
      );
      await tester.pumpAndSettle();

      expect(find.byType(FrostedBottomSheet), findsNothing);
    });

    testWidgets('an upward drag leaves the sheet open', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.drag(find.byType(FrostedBottomSheet), const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(find.byType(FrostedBottomSheet), findsOneWidget);
    });

    testWidgets('no drag dismissal when enableDrag is false', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, enableDrag: false);

      await tester.drag(find.byType(FrostedBottomSheet), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byType(FrostedBottomSheet), findsOneWidget);
    });
  });

  group('FrostedBottomSheet status bar', () {
    Future<void> openTallSheet(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 48);
      tester.view.viewPadding = const FakeViewPadding(top: 48);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.dark(seedColor: seed),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () => showFrostedBottomSheet<void>(
                  context: context,
                  builder: (_) => FrostedBottomSheet(
                    title: 'Catégorie',
                    child: ListView(
                      shrinkWrap: true,
                      children: List<Widget>.generate(
                        40,
                        (int i) => SizedBox(height: 48, child: Text('row $i')),
                      ),
                    ),
                  ),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('a full-height sheet stays clear of the status bar', (
      WidgetTester tester,
    ) async {
      await openTallSheet(tester);

      expect(
        tester.getTopLeft(find.byType(FrostedBottomSheet)).dy,
        greaterThan(48),
      );
    });

    testWidgets('its title clears the status bar too', (
      WidgetTester tester,
    ) async {
      await openTallSheet(tester);

      expect(tester.getTopLeft(find.text('Catégorie')).dy, greaterThan(48));
    });

    testWidgets('a short sheet keeps its natural height', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 48);
      tester.view.viewPadding = const FakeViewPadding(top: 48);
      addTearDown(tester.view.reset);

      await openSheet(tester);

      expect(
        tester.getSize(find.byType(FrostedBottomSheet)).height,
        lessThan(400),
      );
    });
  });
}

double _barrierSigma(WidgetTester tester) {
  final String filter = tester.layers
      .whereType<BackdropFilterLayer>()
      .first
      .filter
      .toString();
  return double.parse(RegExp(r'blur\(([0-9.]+)').firstMatch(filter)!.group(1)!);
}
