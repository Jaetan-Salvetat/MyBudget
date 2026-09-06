import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<void> pump(WidgetTester tester, Widget button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  AnimatedContainer surfaceOf(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(FrostedIconButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
  }

  double glyphSizeOf(WidgetTester tester) {
    return tester
        .widget<Icon>(
          find.descendant(
            of: find.byType(FrostedIconButton),
            matching: find.byType(Icon),
          ),
        )
        .size!;
  }

  Color fillOf(WidgetTester tester) =>
      (surfaceOf(tester).decoration! as BoxDecoration).color!;

  Color glyphColorOf(WidgetTester tester) => tester
      .widget<Icon>(
        find.descendant(
          of: find.byType(FrostedIconButton),
          matching: find.byType(Icon),
        ),
      )
      .color!;

  group('FrostedIconButton accent', () {
    ColorScheme scheme(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(FrostedIconButton))).colorScheme;

    testWidgets('a filled command carries the accent at rest', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FrostedIconButton.filled(icon: Icons.send, onPressed: () {}),
      );

      expect(fillOf(tester), scheme(tester).primary);
      expect(glyphColorOf(tester), scheme(tester).onPrimary);
    });

    testWidgets('a filled toggle waits to be turned on', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FrostedIconButton.filled(
          icon: Icons.send,
          selected: false,
          onPressed: () {},
        ),
      );

      expect(fillOf(tester), scheme(tester).surfaceContainerHighest);

      await pump(
        tester,
        FrostedIconButton.filled(
          icon: Icons.send,
          selected: true,
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(fillOf(tester), scheme(tester).primary);
    });

    testWidgets('a command tells nothing about selection', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FrostedIconButton.filled(icon: Icons.send, onPressed: () {}),
      );

      final SemanticsNode node = tester.getSemantics(
        find.byType(FrostedIconButton),
      );

      expect(node.flagsCollection.isSelected, Tristate.none);
    });
  });

  group('FrostedIconButton size', () {
    testWidgets('defaults to medium', (WidgetTester tester) async {
      await pump(
        tester,
        FrostedIconButton.standard(icon: Icons.add, onPressed: () {}),
      );

      expect(
        surfaceOf(tester).constraints!.maxWidth,
        FrostedIconButtonSize.medium.box,
      );
      expect(glyphSizeOf(tester), FrostedIconButtonSize.medium.glyph);
    });

    testWidgets('small shrinks both the box and the glyph', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FrostedIconButton.standard(
          icon: Icons.add,
          size: FrostedIconButtonSize.small,
          onPressed: () {},
        ),
      );

      expect(
        surfaceOf(tester).constraints!.maxWidth,
        FrostedIconButtonSize.small.box,
      );
      expect(glyphSizeOf(tester), FrostedIconButtonSize.small.glyph);
      expect(
        FrostedIconButtonSize.small.box,
        lessThan(FrostedIconButtonSize.medium.box),
      );
    });

    testWidgets('large grows both the box and the glyph', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FrostedIconButton.filled(
          icon: Icons.add,
          size: FrostedIconButtonSize.large,
          onPressed: () {},
        ),
      );

      expect(
        surfaceOf(tester).constraints!.maxWidth,
        FrostedIconButtonSize.large.box,
      );
      expect(glyphSizeOf(tester), FrostedIconButtonSize.large.glyph);
      expect(
        FrostedIconButtonSize.large.box,
        greaterThan(FrostedIconButtonSize.medium.box),
      );
    });

    testWidgets('the pill form stays a circle at every size', (
      WidgetTester tester,
    ) async {
      for (final FrostedIconButtonSize size in FrostedIconButtonSize.values) {
        await pump(
          tester,
          FrostedIconButton.tonal(
            icon: Icons.add,
            size: size,
            shape: FrostedShape.pill,
            onPressed: () {},
          ),
        );

        final BoxDecoration decoration =
            surfaceOf(tester).decoration! as BoxDecoration;

        expect(
          (decoration.borderRadius! as BorderRadius).topLeft.x,
          size.box / 2,
        );
      }
    });

    testWidgets('every variant accepts a size', (WidgetTester tester) async {
      final List<FrostedIconButton> buttons = <FrostedIconButton>[
        FrostedIconButton.standard(
          icon: Icons.add,
          size: FrostedIconButtonSize.small,
          onPressed: () {},
        ),
        FrostedIconButton.filled(
          icon: Icons.add,
          size: FrostedIconButtonSize.small,
          onPressed: () {},
        ),
        FrostedIconButton.tonal(
          icon: Icons.add,
          size: FrostedIconButtonSize.small,
          onPressed: () {},
        ),
        FrostedIconButton.outlined(
          icon: Icons.add,
          size: FrostedIconButtonSize.small,
          onPressed: () {},
        ),
      ];

      for (final FrostedIconButton button in buttons) {
        await pump(tester, button);
        expect(
          surfaceOf(tester).constraints!.maxWidth,
          FrostedIconButtonSize.small.box,
        );
      }
    });
  });
}
