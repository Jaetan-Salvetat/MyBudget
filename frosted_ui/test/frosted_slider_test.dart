import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

const Rect _track = Rect.fromLTRB(0, 0, 200, 16);

Widget _host(Widget child) => MaterialApp(
  theme: FrostedTheme.dark(seedColor: const Color(0xFF7C5CFF)),
  home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
);

SliderThemeData _themeOf(WidgetTester tester, Type owner) {
  return tester
      .widget<SliderTheme>(
        find
            .descendant(of: find.byType(owner), matching: find.byType(SliderTheme))
            .first,
      )
      .data;
}

void main() {
  group('FrostedSlider', () {
    testWidgets('adopts the M3 expressive geometry', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(FrostedSlider(value: 0.5, onChanged: (_) {})),
      );

      final SliderThemeData theme = _themeOf(tester, FrostedSlider);

      expect(theme.trackHeight, FrostedSliderTokens.trackHeight);
      expect(theme.trackGap, FrostedSliderTokens.handleGap);
      expect(theme.thumbShape, isA<HandleThumbShape>());
      expect(theme.trackShape, isA<GappedSliderTrackShape>());
      expect(theme.showValueIndicator, ShowValueIndicator.onDrag);
      expect(theme.inactiveTrackColor, isNotNull);
    });

    testWidgets('shrinks the handle while pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(FrostedSlider(value: 0.5, onChanged: (_) {})),
      );

      final WidgetStateProperty<Size?> thumbSize = _themeOf(
        tester,
        FrostedSlider,
      ).thumbSize!;

      expect(
        thumbSize.resolve(const <WidgetState>{}),
        const Size(
          FrostedSliderTokens.handleWidth,
          FrostedSliderTokens.handleHeight,
        ),
      );
      expect(
        thumbSize.resolve(const <WidgetState>{WidgetState.pressed}),
        const Size(
          FrostedSliderTokens.pressedHandleWidth,
          FrostedSliderTokens.handleHeight,
        ),
      );
      expect(
        thumbSize.resolve(const <WidgetState>{WidgetState.focused}),
        const Size(
          FrostedSliderTokens.focusedHandleWidth,
          FrostedSliderTokens.handleHeight,
        ),
      );
    });

    testWidgets('centered variant swaps the track shape', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedSlider(
            value: 0.5,
            onChanged: (_) {},
            min: -1,
            track: FrostedSliderTrack.centered,
          ),
        ),
      );

      expect(
        _themeOf(tester, FrostedSlider).trackShape,
        isA<FrostedCenteredSliderTrackShape>(),
      );
    });

    testWidgets('reports the dragged value', (WidgetTester tester) async {
      double value = 0.5;
      await tester.pumpWidget(
        _host(FrostedSlider(value: value, onChanged: (double v) => value = v)),
      );

      await tester.tapAt(
        tester.getTopLeft(find.byType(Slider)) +
            Offset(tester.getSize(find.byType(Slider)).width - 8, 8),
      );

      expect(value, greaterThan(0.5));
    });
  });

  group('FrostedCenteredSliderTrackShape', () {
    const FrostedCenteredSliderTrackShape shape =
        FrostedCenteredSliderTrackShape();

    test('grows from the centre towards a thumb on the right', () {
      expect(shape.activeRect(_track, 160), const Rect.fromLTRB(100, 0, 160, 16));
    });

    test('grows from the centre towards a thumb on the left', () {
      expect(shape.activeRect(_track, 40), const Rect.fromLTRB(40, 0, 100, 16));
    });

    test('collapses at the centre', () {
      expect(shape.activeRect(_track, 100).width, 0);
    });
  });

  group('FrostedRangeSlider', () {
    testWidgets('adopts the M3 expressive geometry', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedRangeSlider(
            values: const RangeValues(0.2, 0.8),
            onChanged: (_) {},
          ),
        ),
      );

      final SliderThemeData theme = _themeOf(tester, FrostedRangeSlider);

      expect(theme.trackHeight, FrostedSliderTokens.trackHeight);
      expect(theme.trackGap, FrostedSliderTokens.handleGap);
      expect(theme.rangeThumbShape, isA<HandleRangeSliderThumbShape>());
      expect(theme.rangeTrackShape, isA<GappedRangeSliderTrackShape>());
    });
  });
}
