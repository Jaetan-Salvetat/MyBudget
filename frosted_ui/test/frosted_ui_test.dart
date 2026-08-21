import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  test('FrostedTheme attaches FrostedTokens to ThemeData', () {
    final ThemeData theme =
        FrostedTheme.dark(seedColor: const Color(0xFF7C5CFF));

    expect(theme.extension<FrostedTokens>(), isNotNull);
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
  });

  testWidgets('FrostedGlass renders with theme tokens',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: FrostedGlass(child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(FrostedGlass), findsOneWidget);
  });

  testWidgets('FrostedGlass blurs with a bounded filter to avoid edge halo',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: FrostedGlass(child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );

    final BackdropFilter backdrop = tester.widget<BackdropFilter>(
      find.descendant(
        of: find.byType(FrostedGlass),
        matching: find.byType(BackdropFilter),
      ),
    );

    expect(backdrop.filter, isNull);
    expect(
      backdrop.filterConfig!.debugShortDescription,
      contains('bounded'),
    );
  });

  testWidgets('FrostedGlass strokes every side by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: FrostedGlass(child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );

    final Border border = _glassBorder(tester);

    expect(border.isUniform, isTrue);
    expect(border.top.style, BorderStyle.solid);
    expect(border.bottom.style, BorderStyle.solid);
    expect(border.left.style, BorderStyle.solid);
    expect(border.right.style, BorderStyle.solid);
  });

  testWidgets('FrostedGlass drops the sides left out of borderEdges',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: FrostedGlass(
                borderRadius: BorderRadius.zero,
                borderEdges: <FrostedGlassEdge>{FrostedGlassEdge.bottom},
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    final Border border = _glassBorder(tester);

    expect(border.bottom.style, BorderStyle.solid);
    expect(border.top, BorderSide.none);
    expect(border.left, BorderSide.none);
    expect(border.right, BorderSide.none);
  });

  testWidgets('FrostedGlass rejects partial edges under a rounded radius',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: FrostedGlass(
                borderRadius: BorderRadius.circular(24),
                borderEdges: const <FrostedGlassEdge>{FrostedGlassEdge.bottom},
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('FrostedTopBar only strokes the edge facing the content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: Colors.deepPurple),
        home: const Scaffold(
          appBar: FrostedTopBar(title: 'Library'),
          body: SizedBox.expand(),
        ),
      ),
    );

    final Border border = _glassBorder(tester);

    expect(border.bottom.style, BorderStyle.solid);
    expect(border.top, BorderSide.none);
    expect(border.left, BorderSide.none);
    expect(border.right, BorderSide.none);
  });
}

Border _glassBorder(WidgetTester tester) {
  final DecoratedBox decorated = tester.widget<DecoratedBox>(
    find.byWidgetPredicate(
      (Widget widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).border != null,
    ),
  );
  return (decorated.decoration as BoxDecoration).border! as Border;
}
