import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);
  const Radius corner = Radius.circular(FrostedRadius.md);

  List<FrostedDropdownItem<int>> items(int count) {
    return <FrostedDropdownItem<int>>[
      for (int i = 0; i < count; i++)
        FrostedDropdownItem<int>(value: i, label: 'Option $i'),
    ];
  }

  Future<void> pump(
    WidgetTester tester, {
    int count = 3,
    Alignment alignment = Alignment.topCenter,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.light(seedColor: seed),
        home: Scaffold(
          body: Align(
            alignment: alignment,
            child: SizedBox(
              width: 280,
              child: FrostedDropdown<int>(
                value: 0,
                onChanged: (_) {},
                items: items(count),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius fieldRadius(WidgetTester tester) {
    return tester
            .widget<FrostedFieldSurface>(find.byType(FrostedFieldSurface))
            .borderRadius ??
        BorderRadius.circular(FrostedRadius.md);
  }

  BorderRadius panelRadius(WidgetTester tester) {
    return tester
            .widget<FrostedMenuPanel>(find.byType(FrostedMenuPanel))
            .borderRadius ??
        BorderRadius.circular(FrostedRadius.md);
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byType(FrostedFieldSurface));
    await tester.pumpAndSettle();
  }

  group('FrostedDropdown shape', () {
    testWidgets('rounds every corner while closed', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(fieldRadius(tester), const BorderRadius.all(corner));
    });

    testWidgets('flattens the joined edges while open', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await open(tester);

      expect(fieldRadius(tester), const BorderRadius.vertical(top: corner));
      expect(panelRadius(tester), const BorderRadius.vertical(bottom: corner));
    });

    testWidgets('stays below the field when room is short', (
      WidgetTester tester,
    ) async {
      await pump(tester, count: 40, alignment: Alignment.bottomCenter);
      final Rect field = tester.getRect(find.byType(FrostedFieldSurface));
      await open(tester);

      final Rect panel = tester.getRect(find.byType(FrostedMenuPanel));
      expect(panel.top, field.bottom);
      expect(fieldRadius(tester), const BorderRadius.vertical(top: corner));
      expect(panelRadius(tester), const BorderRadius.vertical(bottom: corner));
    });

    testWidgets('drops the focus ring while open', (WidgetTester tester) async {
      await pump(tester);
      await open(tester);

      expect(
        tester
            .widget<FrostedFieldSurface>(find.byType(FrostedFieldSurface))
            .focused,
        isFalse,
      );
    });

    testWidgets('sits flush against the field', (WidgetTester tester) async {
      await pump(tester);
      final Rect field = tester.getRect(find.byType(FrostedFieldSurface));
      await open(tester);

      final Rect panel = tester.getRect(find.byType(FrostedMenuPanel));
      expect(panel.top, field.bottom);
      expect(panel.left, field.left);
      expect(panel.width, field.width);
    });
  });

  group('FrostedDropdown menu height', () {
    testWidgets('keeps a long list inside the viewport', (
      WidgetTester tester,
    ) async {
      await pump(tester, count: 40);
      await open(tester);

      final Rect panel = tester.getRect(find.byType(FrostedMenuPanel));
      expect(
        panel.bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height / tester.view.devicePixelRatio),
      );
      expect(find.byType(Scrollable), findsWidgets);
    });
  });
}
