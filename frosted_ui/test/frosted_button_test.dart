import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<ColorScheme> pump(WidgetTester tester, Widget button) async {
    late ColorScheme scheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
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
