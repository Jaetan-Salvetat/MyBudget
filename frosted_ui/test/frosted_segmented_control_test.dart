import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

class _PaintedRRect {
  const _PaintedRRect(this.rrect, this.color, this.order);

  final RRect rrect;
  final Color color;
  final int order;
}

class _ControlPaints {
  const _ControlPaints(this.rrects, this.splashOrder);

  final List<_PaintedRRect> rrects;
  final int? splashOrder;

  _PaintedRRect get container => rrects.first;

  _PaintedRRect thumbOf(Color color) =>
      rrects.firstWhere((_PaintedRRect r) => _sameColor(r.color, color));
}

bool _sameColor(Color a, Color b) => a.toARGB32() == b.toARGB32();

void main() {
  const Color seed = Color(0xFF7C5CFF);
  const Color splash = Color(0xFF00FF00);
  const List<String> segments = <String>['6 mois', '12 mois'];
  const double padding = 3;
  const double height = 32;

  ThemeData theme() => FrostedTheme.dark(
    seedColor: seed,
  ).copyWith(splashFactory: InkSplash.splashFactory, splashColor: splash);

  Future<void> pump(WidgetTester tester, Widget control, {double? width}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme(),
        home: Scaffold(
          body: Center(
            child: width == null
                ? control
                : SizedBox(width: width, child: control),
          ),
        ),
      ),
    );
  }

  _ControlPaints inspect(WidgetTester tester) {
    final List<_PaintedRRect> rrects = <_PaintedRRect>[];
    int? splashOrder;
    int order = 0;
    Offset origin = Offset.zero;
    final List<Offset> saved = <Offset>[];

    expect(
      tester.renderObject(find.byType(FrostedSegmentedControl)),
      paints..everything((Symbol method, List<dynamic> arguments) {
        switch (method) {
          case #save:
          case #saveLayer:
            saved.add(origin);
          case #restore:
            if (saved.isNotEmpty) origin = saved.removeLast();
          case #translate:
            origin += Offset(arguments[0] as double, arguments[1] as double);
          case #drawRRect:
            rrects.add(
              _PaintedRRect(
                (arguments[0] as RRect).shift(origin),
                (arguments[1] as Paint).color,
                order++,
              ),
            );
          case #drawCircle:
            final Color color = (arguments[2] as Paint).color;
            if (color.toARGB32() == splash.toARGB32()) splashOrder ??= order++;
        }
        return true;
      }),
    );

    return _ControlPaints(rrects, splashOrder);
  }

  testWidgets('reports the tapped segment by index', (
    WidgetTester tester,
  ) async {
    final List<int> tapped = <int>[];
    await pump(
      tester,
      FrostedSegmentedControl(
        segments: segments,
        currentIndex: 0,
        onTap: tapped.add,
      ),
      width: 240,
    );

    await tester.tapAt(tester.getCenter(find.text('12 mois')));
    await tester.pumpAndSettle();

    expect(tapped, <int>[1]);
  });

  testWidgets('seats the selected thumb inside the container padding', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      FrostedSegmentedControl(
        segments: segments,
        currentIndex: 1,
        onTap: (int _) {},
      ),
      width: 240,
    );

    final Rect control = tester.getRect(find.byType(FrostedSegmentedControl));
    final Rect thumb = inspect(
      tester,
    ).thumbOf(theme().colorScheme.surface).rrect.outerRect;
    final double segmentWidth = (control.width - padding * 2) / segments.length;

    expect(thumb.left, moreOrLessEquals(padding + segmentWidth));
    expect(thumb.top, moreOrLessEquals(padding));
    expect(thumb.width, moreOrLessEquals(segmentWidth));
    expect(thumb.height, moreOrLessEquals(height));
    expect(thumb.right, moreOrLessEquals(control.width - padding));
  });

  testWidgets('rounds every segment concentrically with the container', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      FrostedSegmentedControl(
        segments: segments,
        currentIndex: 0,
        onTap: (int _) {},
      ),
      width: 240,
    );

    final _ControlPaints paints = inspect(tester);
    final double innerRadius = paints.container.rrect.tlRadiusX - padding;

    expect(paints.rrects.length, greaterThan(segments.length));
    for (final _PaintedRRect painted in paints.rrects.skip(1)) {
      expect(painted.rrect.tlRadiusX, moreOrLessEquals(innerRadius));
      expect(painted.rrect.blRadiusX, moreOrLessEquals(innerRadius));
    }
  });

  testWidgets('keeps the press ink under the selected thumb', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      FrostedSegmentedControl(
        segments: segments,
        currentIndex: 0,
        onTap: (int _) {},
      ),
      width: 240,
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('6 mois')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final _ControlPaints paints = inspect(tester);
    expect(paints.splashOrder, isNotNull);
    expect(
      paints.splashOrder,
      lessThan(paints.thumbOf(theme().colorScheme.surface).order),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('sizes itself to its segments when a segment width is given', (
    WidgetTester tester,
  ) async {
    const double segmentWidth = 70;
    await pump(
      tester,
      FrostedSegmentedControl(
        segments: segments,
        currentIndex: 0,
        onTap: (int _) {},
        segmentWidth: segmentWidth,
      ),
    );

    expect(
      tester.getSize(find.byType(FrostedSegmentedControl)).width,
      moreOrLessEquals(segmentWidth * segments.length + padding * 2),
    );
  });
}
