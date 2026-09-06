import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

const Size _buttonBox = Size(200, 46);
const Size _iconButtonBox = Size(40, 40);

BorderRadius _renderedRadius(WidgetTester tester, Type owner) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.descendant(
            of: find.byType(owner),
            matching: find.byType(AnimatedContainer),
          ),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  final BoxDecoration decoration = box.decoration as BoxDecoration;
  return decoration.borderRadius! as BorderRadius;
}

Future<void> _press(WidgetTester tester, Finder target) async {
  await tester.startGesture(tester.getCenter(target));
  await tester.pumpAndSettle();
}

Widget _host(Widget child) => MaterialApp(
  theme: FrostedTheme.dark(seedColor: const Color(0xFF7C5CFF)),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('FrostedShape', () {
    test('morphs into its opposite', () {
      expect(FrostedShape.pill.opposite, FrostedShape.rounded);
      expect(FrostedShape.rounded.opposite, FrostedShape.pill);
    });

    test('pill is half the shortest side', () {
      expect(FrostedShape.pill.radiusFor(_buttonBox), 23);
      expect(FrostedShape.pill.radiusFor(_iconButtonBox), 20);
    });

    test('pill on a square box is a circle', () {
      expect(
        FrostedShape.pill.radiusFor(_iconButtonBox),
        _iconButtonBox.shortestSide / 2,
      );
    });

    test('rounded uses the md token', () {
      expect(FrostedShape.rounded.radiusFor(_buttonBox), FrostedRadius.md);
    });

    test('rounded is capped at half the shortest side', () {
      expect(FrostedShape.rounded.radiusFor(const Size(16, 16)), 8);
    });

    test('rounded takes the radius the component asks for', () {
      expect(
        FrostedShape.rounded.radiusFor(
          const Size(96, 96),
          roundedRadius: FrostedRadius.xxl,
        ),
        FrostedRadius.xxl,
      );
    });

    test('pill ignores the rounded radius', () {
      expect(
        FrostedShape.pill.radiusFor(
          const Size(96, 96),
          roundedRadius: FrostedRadius.xxl,
        ),
        48,
      );
    });

    test('resolve swaps the form while pressed', () {
      expect(
        FrostedShape.pill.resolve(_buttonBox, pressed: false),
        BorderRadius.circular(23),
      );
      expect(
        FrostedShape.pill.resolve(_buttonBox, pressed: true),
        BorderRadius.circular(FrostedRadius.md),
      );
      expect(
        FrostedShape.rounded.resolve(_buttonBox, pressed: false),
        BorderRadius.circular(FrostedRadius.md),
      );
      expect(
        FrostedShape.rounded.resolve(_buttonBox, pressed: true),
        BorderRadius.circular(23),
      );
    });
  });

  group('FrostedButton shape morphing', () {
    testWidgets('pill flattens to rounded on press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedButton.filled(
            label: 'Valider',
            shape: FrostedShape.pill,
            onPressed: () {},
          ),
        ),
      );

      expect(_renderedRadius(tester, FrostedButton), BorderRadius.circular(23));

      await _press(tester, find.byType(FrostedButton));

      expect(
        _renderedRadius(tester, FrostedButton),
        BorderRadius.circular(FrostedRadius.md),
      );
    });

    testWidgets('rounded rounds out to pill on press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedButton.filled(
            label: 'Valider',
            shape: FrostedShape.rounded,
            onPressed: () {},
          ),
        ),
      );

      expect(
        _renderedRadius(tester, FrostedButton),
        BorderRadius.circular(FrostedRadius.md),
      );

      await _press(tester, find.byType(FrostedButton));

      expect(_renderedRadius(tester, FrostedButton), BorderRadius.circular(23));
    });

    testWidgets('keeps a fixed height so the pill radius is exact', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(FrostedButton.filled(label: 'Valider', onPressed: () {})),
      );

      expect(tester.getSize(find.byType(FrostedButton)).height, 46);
    });

    testWidgets('a disabled button does not morph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedButton.filled(
            label: 'Valider',
            shape: FrostedShape.pill,
            onPressed: null,
          ),
        ),
      );

      await _press(tester, find.byType(FrostedButton));

      expect(_renderedRadius(tester, FrostedButton), BorderRadius.circular(23));
    });
  });

  group('FrostedFab shape morphing', () {
    testWidgets('pill is a circle at rest and rounded on press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(FrostedFab.large(icon: Icons.bolt, onPressed: () {})),
      );

      expect(_renderedRadius(tester, FrostedFab), BorderRadius.circular(48));

      await _press(tester, find.byType(FrostedFab));

      expect(
        _renderedRadius(tester, FrostedFab),
        BorderRadius.circular(FrostedRadius.xxl),
      );
    });

    testWidgets('each size carries its own rounded radius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedFab.small(
            icon: Icons.add,
            shape: FrostedShape.rounded,
            onPressed: () {},
          ),
        ),
      );

      expect(
        _renderedRadius(tester, FrostedFab),
        BorderRadius.circular(FrostedRadius.md),
      );

      await _press(tester, find.byType(FrostedFab));

      expect(_renderedRadius(tester, FrostedFab), BorderRadius.circular(20));
    });

    testWidgets('an extended fab resolves the pill against its height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedFab.extended(
            icon: Icons.add,
            label: 'Compose',
            onPressed: () {},
          ),
        ),
      );

      expect(_renderedRadius(tester, FrostedFab), BorderRadius.circular(28));

      await _press(tester, find.byType(FrostedFab));

      expect(
        _renderedRadius(tester, FrostedFab),
        BorderRadius.circular(FrostedRadius.lg),
      );
    });
  });

  group('FrostedIconButton shape morphing', () {
    testWidgets('pill is a circle at rest and rounded on press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedIconButton.filled(
            icon: Icons.add,
            shape: FrostedShape.pill,
            onPressed: () {},
          ),
        ),
      );

      expect(
        _renderedRadius(tester, FrostedIconButton),
        BorderRadius.circular(20),
      );

      await _press(tester, find.byType(FrostedIconButton));

      expect(
        _renderedRadius(tester, FrostedIconButton),
        BorderRadius.circular(FrostedRadius.md),
      );
    });

    testWidgets('rounded becomes a circle on press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FrostedIconButton.filled(
            icon: Icons.add,
            shape: FrostedShape.rounded,
            onPressed: () {},
          ),
        ),
      );

      expect(
        _renderedRadius(tester, FrostedIconButton),
        BorderRadius.circular(FrostedRadius.md),
      );

      await _press(tester, find.byType(FrostedIconButton));

      expect(
        _renderedRadius(tester, FrostedIconButton),
        BorderRadius.circular(20),
      );
    });
  });
}
