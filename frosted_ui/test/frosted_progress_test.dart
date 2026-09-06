import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/components/overlays/_circular_progress_painter.dart';
import 'package:frosted_ui/src/components/overlays/_linear_progress_painter.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: FrostedTheme.dark(seedColor: const Color(0xFF7C5CFF)),
  home: Scaffold(body: Center(child: child)),
);

CustomPaint _painterHost(WidgetTester tester, Type owner) => tester.widget(
  find.descendant(of: find.byType(owner), matching: find.byType(CustomPaint)),
);

Matcher _segments(List<List<double>> expected) =>
    pairwiseCompare<List<double>, LinearProgressSegment>(
      expected,
      (List<double> want, LinearProgressSegment got) =>
          (got.tail - want[0]).abs() < 1e-9 &&
          (got.head - want[1]).abs() < 1e-9,
      'matches the expected track segments',
    );

LinearProgressPainter _painter(List<LinearProgressSegment> segments) =>
    LinearProgressPainter(
      segments: segments,
      color: const Color(0xFFFFFFFF),
      trackColor: const Color(0xFF000000),
      showStopIndicator: false,
      textDirection: TextDirection.ltr,
    );

void main() {
  group('LinearProgressPainter.trackSegments', () {
    test('leaves a gap ahead of a determinate bar', () {
      expect(
        _painter(const <LinearProgressSegment>[
          LinearProgressSegment(0, 0.5),
        ]).trackSegments(0.01),
        _segments(<List<double>>[
          <double>[0.51, 1],
        ]),
      );
    });

    test('ramps the gap in while the bar is shorter than it', () {
      expect(
        _painter(const <LinearProgressSegment>[
          LinearProgressSegment(0, 0.004),
        ]).trackSegments(0.01),
        _segments(<List<double>>[
          <double>[0.008, 1],
        ]),
      );
    });

    test('fills the track between two indeterminate bars', () {
      expect(
        _painter(const <LinearProgressSegment>[
          LinearProgressSegment(0.7, 0.9),
          LinearProgressSegment(0.2, 0.4),
        ]).trackSegments(0.01),
        _segments(<List<double>>[
          <double>[0.91, 1],
          <double>[0.41, 0.69],
          <double>[0, 0.19],
        ]),
      );
    });

    test('reaches the end once a bar has left the track', () {
      final List<LinearProgressSegment> tracks = _painter(
        const <LinearProgressSegment>[
          LinearProgressSegment(1, 1),
          LinearProgressSegment(0.4, 0.6),
        ],
      ).trackSegments(0.01);

      expect(tracks.first.head, 1);
      expect(tracks.first.tail, closeTo(0.61, 1e-9));
    });

    test('covers the whole track when nothing is running', () {
      expect(
        _painter(const <LinearProgressSegment>[
          LinearProgressSegment(0, 0),
        ]).trackSegments(0.01),
        _segments(<List<double>>[
          <double>[0, 1],
        ]),
      );
    });
  });

  group('FrostedLinearProgress', () {
    testWidgets('defaults to the M3 track thickness', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const FrostedLinearProgress(value: 0.5)));

      expect(
        tester.getSize(find.byType(FrostedLinearProgress)).height,
        FrostedProgressTokens.linearThickness,
      );
    });

    testWidgets('honours a custom thickness', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const FrostedLinearProgress(value: 0.5, thickness: 12)),
      );

      expect(tester.getSize(find.byType(FrostedLinearProgress)).height, 12);
    });

    testWidgets('draws the stop indicator only when determinate', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const FrostedLinearProgress(value: 0.5)));
      expect(
        (_painterHost(tester, FrostedLinearProgress).painter!
                as LinearProgressPainter)
            .showStopIndicator,
        isTrue,
      );

      await tester.pumpWidget(_host(const FrostedLinearProgress()));
      expect(
        (_painterHost(tester, FrostedLinearProgress).painter!
                as LinearProgressPainter)
            .showStopIndicator,
        isFalse,
      );

      await tester.pumpWidget(_host(const SizedBox.shrink()));
    });

    testWidgets('settles on a progress change', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const FrostedLinearProgress(value: 0)));
      await tester.pumpWidget(_host(const FrostedLinearProgress(value: 1)));
      await tester.pump(const Duration(milliseconds: 1));

      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpAndSettle();

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('indeterminate keeps ticking', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const FrostedLinearProgress()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(_host(const SizedBox.shrink()));
    });
  });

  group('FrostedCircularProgress', () {
    testWidgets('defaults to the M3 container size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const FrostedCircularProgress(value: 0.5)));

      expect(
        tester.getSize(find.byType(FrostedCircularProgress)),
        const Size.square(FrostedProgressTokens.circularSize),
      );
    });

    testWidgets('honours a custom size and thickness', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FrostedCircularProgress(value: 0.5, size: 64, thickness: 8),
        ),
      );

      expect(
        tester.getSize(find.byType(FrostedCircularProgress)),
        const Size.square(64),
      );
      expect(
        (_painterHost(tester, FrostedCircularProgress).painter!
                as CircularProgressPainter)
            .thickness,
        8,
      );
    });

    testWidgets('keeps the track in both modes', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const FrostedCircularProgress(value: 0.5)));
      final ColorScheme cs = Theme.of(
        tester.element(find.byType(FrostedCircularProgress)),
      ).colorScheme;
      expect(
        (_painterHost(tester, FrostedCircularProgress).painter!
                as CircularProgressPainter)
            .trackColor,
        cs.secondaryContainer,
      );

      await tester.pumpWidget(_host(const FrostedCircularProgress()));
      expect(
        (_painterHost(tester, FrostedCircularProgress).painter!
                as CircularProgressPainter)
            .trackColor,
        cs.secondaryContainer,
      );

      await tester.pumpWidget(_host(const SizedBox.shrink()));
    });

    testWidgets('indeterminate keeps ticking', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const FrostedCircularProgress()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(_host(const SizedBox.shrink()));
    });
  });
}
