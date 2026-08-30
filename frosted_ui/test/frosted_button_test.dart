import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<ColorScheme> pump(WidgetTester tester, Widget button) async {
    late ColorScheme scheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(
          seedColor: seed,
        ).copyWith(splashFactory: InkSplash.splashFactory),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              scheme = Theme.of(context).colorScheme;
              return Center(child: button);
            },
          ),
        ),
      ),
    );
    return scheme;
  }

  Color backgroundOf(WidgetTester tester) {
    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(FrostedButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  Color labelColorOf(WidgetTester tester) {
    final Text text = tester.widget<Text>(
      find.descendant(
        of: find.byType(FrostedButton),
        matching: find.byType(Text),
      ),
    );
    return text.style!.color!;
  }

  double cornerRadiusOf(WidgetTester tester) {
    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(FrostedButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final BoxDecoration decoration = container.decoration! as BoxDecoration;
    return (decoration.borderRadius! as BorderRadius).topLeft.x;
  }

  BoxDecoration paintedOf(WidgetTester tester) {
    final RenderDecoratedBox box = tester.renderObject<RenderDecoratedBox>(
      find.descendant(
        of: find.byType(FrostedButton),
        matching: find.byType(DecoratedBox),
      ),
    );
    return box.decoration as BoxDecoration;
  }

  double splashRadiusOf(WidgetTester tester) {
    double? radius;
    expect(
      tester.renderObject(find.byType(FrostedButton)),
      paints
        ..something((Symbol method, List<dynamic> arguments) {
          if (method != #drawCircle) return false;
          radius = arguments[1] as double;
          return true;
        }),
    );
    return radius!;
  }

  group('FrostedButton press feedback', () {
    testWidgets('splashes from the point pressed',
        (WidgetTester tester) async {
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: () {}),
      );
      final Finder button = find.byType(FrostedButton);

      expect(tester.renderObject(button), isNot(paints..circle()));

      final TestGesture gesture = await tester.startGesture(
        tester.getTopLeft(button) + const Offset(12, 10),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        tester.renderObject(button),
        paints..circle(x: 12, y: 10),
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.renderObject(button), isNot(paints..circle()));
    });

    testWidgets('grows the splash while it plays', (WidgetTester tester) async {
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: () {}),
      );
      final Finder button = find.byType(FrostedButton);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(button),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final double early = splashRadiusOf(tester);

      await tester.pump(const Duration(milliseconds: 120));

      expect(splashRadiusOf(tester), greaterThan(early));
      expect(early, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a disabled button raises no ink',
        (WidgetTester tester) async {
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: null),
      );
      final Finder button = find.byType(FrostedButton);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(button),
      );
      await tester.pump(const Duration(milliseconds: 80));

      expect(tester.renderObject(button), isNot(paints..circle()));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('fades its press layer in instead of popping it',
        (WidgetTester tester) async {
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: () {}),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(FrostedButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final double early = paintedOf(tester).color!.a;

      await tester.pump(const Duration(milliseconds: 190));
      final double settled = paintedOf(tester).color!.a;

      expect(settled, greaterThan(0));
      expect(settled, greaterThanOrEqualTo(0.15));
      expect(early, lessThan(settled * 0.10));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('morphs the shape gradually rather than snapping',
        (WidgetTester tester) async {
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: () {}),
      );
      final double resting =
          (paintedOf(tester).borderRadius! as BorderRadius).topLeft.x;

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(FrostedButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final double early =
          (paintedOf(tester).borderRadius! as BorderRadius).topLeft.x;

      await tester.pump(const Duration(milliseconds: 190));
      final double settled =
          (paintedOf(tester).borderRadius! as BorderRadius).topLeft.x;

      expect(settled, greaterThan(resting));
      expect(early - resting, lessThan((settled - resting) * 0.10));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('holds the pressed shape past a tap too quick to read',
        (WidgetTester tester) async {
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: () {}),
      );
      final double resting = cornerRadiusOf(tester);

      await tester.tap(find.byType(FrostedButton));
      await tester.pump();

      expect(cornerRadiusOf(tester), greaterThan(resting));

      await tester.pumpAndSettle();

      expect(cornerRadiusOf(tester), resting);
    });

    testWidgets('holds the pressed tint on a transparent text button',
        (WidgetTester tester) async {
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: () {}),
      );

      expect(backgroundOf(tester), Colors.transparent);

      await tester.tap(find.byType(FrostedButton));
      await tester.pump();

      expect(backgroundOf(tester).a, greaterThan(0));

      await tester.pumpAndSettle();

      expect(backgroundOf(tester), Colors.transparent);
    });

    testWidgets('releases the pressed state when the tap is cancelled',
        (WidgetTester tester) async {
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: () {}),
      );
      final double resting = cornerRadiusOf(tester);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(FrostedButton)),
      );
      await tester.pump(const Duration(milliseconds: 120));

      expect(cornerRadiusOf(tester), greaterThan(resting));

      await gesture.moveBy(const Offset(0, 200));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(cornerRadiusOf(tester), resting);
    });

    testWidgets('fires the callback once per tap', (WidgetTester tester) async {
      int taps = 0;
      await pump(
        tester,
        FrostedButton.text(label: 'Annuler', onPressed: () => taps++),
      );

      await tester.tap(find.byType(FrostedButton));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('FrostedButton destructive', () {
    testWidgets('filled paints the error role instead of primary',
        (WidgetTester tester) async {
      final ColorScheme cs = await pump(
        tester,
        FrostedButton.filled(
          label: 'Supprimer',
          destructive: true,
          onPressed: () {},
        ),
      );

      expect(backgroundOf(tester), cs.error);
      expect(labelColorOf(tester), cs.onError);
    });

    testWidgets('text tints the label with the error role',
        (WidgetTester tester) async {
      final ColorScheme cs = await pump(
        tester,
        FrostedButton.text(
          label: 'Supprimer',
          destructive: true,
          onPressed: () {},
        ),
      );

      expect(labelColorOf(tester), cs.error);
    });

    testWidgets('tonal fills the error container',
        (WidgetTester tester) async {
      final ColorScheme cs = await pump(
        tester,
        FrostedButton.tonal(
          label: 'Supprimer',
          destructive: true,
          onPressed: () {},
        ),
      );

      expect(backgroundOf(tester), cs.errorContainer);
      expect(labelColorOf(tester), cs.onErrorContainer);
    });

    testWidgets('outlined tints its border with the error role',
        (WidgetTester tester) async {
      final ColorScheme cs = await pump(
        tester,
        FrostedButton.outlined(
          label: 'Supprimer',
          destructive: true,
          onPressed: () {},
        ),
      );

      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(FrostedButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final BoxDecoration decoration = container.decoration! as BoxDecoration;

      expect(decoration.border!.top.color, cs.error);
      expect(labelColorOf(tester), cs.error);
    });

    testWidgets('defaults to the primary role when not destructive',
        (WidgetTester tester) async {
      final ColorScheme cs = await pump(
        tester,
        FrostedButton.filled(label: 'Enregistrer', onPressed: () {}),
      );

      expect(backgroundOf(tester), cs.primary);
      expect(labelColorOf(tester), cs.onPrimary);
    });

    testWidgets('disabled keeps the neutral disabled roles',
        (WidgetTester tester) async {
      final ColorScheme cs = await pump(
        tester,
        FrostedButton.filled(
          label: 'Supprimer',
          destructive: true,
          onPressed: null,
        ),
      );

      expect(backgroundOf(tester), cs.onSurface.withValues(alpha: 0.12));
      expect(labelColorOf(tester), cs.onSurface.withValues(alpha: 0.38));
    });
  });
}
