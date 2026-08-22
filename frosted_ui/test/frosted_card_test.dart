import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<void> pump(WidgetTester tester, Widget card) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(body: Center(child: card)),
      ),
    );
  }

  double topLeftRadiusOf(WidgetTester tester, Type container) {
    final Widget widget = tester.widget(
      find.descendant(
        of: find.byType(FrostedCard),
        matching: find.byType(container),
      ),
    );
    final BoxDecoration decoration = (widget is DecoratedBox
            ? widget.decoration
            : (widget as AnimatedContainer).decoration!)
        as BoxDecoration;
    return (decoration.borderRadius! as BorderRadius).topLeft.x;
  }

  group('FrostedRadius.stepDown', () {
    test('walks one step down the token scale', () {
      expect(FrostedRadius.stepDown(FrostedRadius.xxl), FrostedRadius.xl);
      expect(FrostedRadius.stepDown(FrostedRadius.xl), FrostedRadius.lg);
      expect(FrostedRadius.stepDown(FrostedRadius.lg), FrostedRadius.md);
      expect(FrostedRadius.stepDown(FrostedRadius.md), FrostedRadius.sm);
      expect(FrostedRadius.stepDown(FrostedRadius.sm), FrostedRadius.xs);
      expect(FrostedRadius.stepDown(FrostedRadius.xs), FrostedRadius.none);
    });

    test('bottoms out at none', () {
      expect(FrostedRadius.stepDown(FrostedRadius.none), FrostedRadius.none);
    });

    test('snaps an off-scale value to the largest token below it', () {
      expect(FrostedRadius.stepDown(20), FrostedRadius.lg);
    });
  });

  group('FrostedCard radius', () {
    testWidgets('defaults to the lg token', (WidgetTester tester) async {
      await pump(tester, const FrostedCard(child: SizedBox(width: 100)));

      expect(topLeftRadiusOf(tester, DecoratedBox), FrostedRadius.lg);
    });

    testWidgets('honours an explicit token', (WidgetTester tester) async {
      await pump(
        tester,
        const FrostedCard(
          radius: FrostedRadius.xl,
          child: SizedBox(width: 100),
        ),
      );

      expect(topLeftRadiusOf(tester, DecoratedBox), FrostedRadius.xl);
    });

    testWidgets('softens one step down while pressed',
        (WidgetTester tester) async {
      await pump(
        tester,
        FrostedCard(
          radius: FrostedRadius.xl,
          onTap: () {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      expect(topLeftRadiusOf(tester, AnimatedContainer), FrostedRadius.xl);

      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(find.byType(FrostedCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(topLeftRadiusOf(tester, AnimatedContainer), FrostedRadius.lg);

      await gesture.up();
    });

    testWidgets('applies the radius to every variant',
        (WidgetTester tester) async {
      for (final FrostedCardVariant variant in FrostedCardVariant.values) {
        await pump(
          tester,
          FrostedCard(
            variant: variant,
            radius: FrostedRadius.md,
            child: const SizedBox(width: 100),
          ),
        );

        expect(topLeftRadiusOf(tester, DecoratedBox), FrostedRadius.md);
      }
    });
  });
}
