import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  String blurDescription(WidgetTester tester) {
    final BackdropFilterLayer layer =
        tester.layers.whereType<BackdropFilterLayer>().first;
    return layer.filter.toString();
  }

  Future<void> pumpGlass(WidgetTester tester, Widget Function(Widget) wrap) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Align(
          alignment: Alignment.topLeft,
          child: wrap(
            const SizedBox(
              width: 100,
              height: 80,
              child: FrostedGlass(child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
  }

  group('FrostedGlass suspension', () {
    Future<void> pumpSuspended(WidgetTester tester, bool suspended) {
      return tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.dark(seedColor: seed),
          home: FrostedGlassSuspension(
            suspended: suspended,
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                height: 80,
                child: FrostedGlass(child: SizedBox.expand()),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('glass blurs the page when nothing rasterizes it', (
      WidgetTester tester,
    ) async {
      await pumpSuspended(tester, false);

      expect(tester.layers.whereType<BackdropFilterLayer>(), isNotEmpty);
    });

    testWidgets('glass drops its backdrop while an ancestor rasterizes it', (
      WidgetTester tester,
    ) async {
      await pumpSuspended(tester, true);

      expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
    });

    testWidgets('glass takes its backdrop back once the ancestor lets go', (
      WidgetTester tester,
    ) async {
      await pumpSuspended(tester, true);
      await pumpSuspended(tester, false);

      expect(tester.layers.whereType<BackdropFilterLayer>(), isNotEmpty);
    });
  });

  group('FrostedGlass edge', () {
    Future<void> pumpElevated(
      WidgetTester tester, {
      required Brightness brightness,
      required FrostedGlassElevation elevation,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark
              ? FrostedTheme.dark(seedColor: seed)
              : FrostedTheme.light(seedColor: seed),
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 80,
              child: FrostedGlass(
                elevation: elevation,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
    }

    BorderSide edgeOf(WidgetTester tester) {
      final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FrostedGlass),
          matching: find.byType(DecoratedBox),
        ),
      );
      final BoxDecoration decoration = boxes
          .map((DecoratedBox box) => box.decoration as BoxDecoration)
          .firstWhere((BoxDecoration d) => d.border != null);
      return (decoration.border! as Border).top;
    }

    List<BoxShadow>? shadowOf(WidgetTester tester) {
      final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FrostedGlass),
          matching: find.byType(DecoratedBox),
        ),
      );
      return boxes
          .map((DecoratedBox box) => box.decoration as BoxDecoration)
          .firstWhere((BoxDecoration d) => d.borderRadius != null)
          .boxShadow;
    }

    testWidgets('the elevation scale deepens one step at a time', (
      WidgetTester tester,
    ) async {
      final List<double> alphas = <double>[];
      for (final FrostedGlassElevation elevation in <FrostedGlassElevation>[
        FrostedGlassElevation.resting,
        FrostedGlassElevation.floating,
        FrostedGlassElevation.lifted,
      ]) {
        await pumpElevated(
          tester,
          brightness: Brightness.light,
          elevation: elevation,
        );
        alphas.add(shadowOf(tester)!.single.color.a);
      }

      expect(alphas[0], lessThan(alphas[1]));
      expect(alphas[1], lessThan(alphas[2]));
    });

    testWidgets('a resting surface still reads as detached', (
      WidgetTester tester,
    ) async {
      await pumpElevated(
        tester,
        brightness: Brightness.light,
        elevation: FrostedGlassElevation.none,
      );
      final double flush = edgeOf(tester).color.a;

      await pumpElevated(
        tester,
        brightness: Brightness.light,
        elevation: FrostedGlassElevation.resting,
      );

      expect(shadowOf(tester), isNotNull);
      expect(edgeOf(tester).color.a, greaterThan(flush));
    });

    for (final Brightness brightness in Brightness.values) {
      testWidgets('a detached surface carries a crisper hairline in '
          '${brightness.name}', (WidgetTester tester) async {
        await pumpElevated(
          tester,
          brightness: brightness,
          elevation: FrostedGlassElevation.none,
        );
        final double flush = edgeOf(tester).color.a;

        await pumpElevated(
          tester,
          brightness: brightness,
          elevation: FrostedGlassElevation.floating,
        );
        final double detached = edgeOf(tester).color.a;

        expect(detached, greaterThan(flush));
      });
    }
  });

  group('FrostedGlass bounded blur', () {
    testWidgets('bounds match the surface when it sits at the layer origin', (
      WidgetTester tester,
    ) async {
      await pumpGlass(tester, (Widget child) => child);

      expect(
        blurDescription(tester),
        contains('bounds: Rect.fromLTRB(0.0, 0.0, 100.0, 80.0)'),
      );
    });

    testWidgets('bounds follow the surface across a compositing layer', (
      WidgetTester tester,
    ) async {
      await pumpGlass(
        tester,
        (Widget child) => Padding(
          padding: const EdgeInsets.only(left: 40, top: 60),
          child: RepaintBoundary(child: child),
        ),
      );

      expect(
        blurDescription(tester),
        contains('bounds: Rect.fromLTRB(40.0, 60.0, 140.0, 140.0)'),
      );
    });

    testWidgets('bounds follow the surface across a transform layer', (
      WidgetTester tester,
    ) async {
      await pumpGlass(
        tester,
        (Widget child) => Transform.translate(
          offset: const Offset(40, 60),
          child: RepaintBoundary(child: child),
        ),
      );

      expect(
        blurDescription(tester),
        contains('bounds: Rect.fromLTRB(40.0, 60.0, 140.0, 140.0)'),
      );
    });
  });
}
