import 'package:flutter/material.dart';
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
