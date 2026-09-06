import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_thinking_border.dart';

void main() {
  Future<void> pumpBorder(
    WidgetTester tester, {
    required bool thinking,
    Widget? child,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: QuickAddThinkingBorder(
            thinking: thinking,
            child: child ?? const SizedBox(width: 200, height: 48),
          ),
        ),
      ),
    );
  }

  Finder sweepPainter() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is QuickAddThinkingBorderPainter,
    );
  }

  testWidgets('stays invisible while the model has nothing to read', (
    tester,
  ) async {
    await pumpBorder(tester, thinking: false);

    expect(sweepPainter(), findsNothing);
  });

  testWidgets('sweeps around the field while the model reads', (tester) async {
    await pumpBorder(tester, thinking: true);
    await tester.pump(const Duration(milliseconds: 300));

    expect(sweepPainter(), findsOneWidget);
  });

  testWidgets('fades out once the reading has landed', (tester) async {
    await pumpBorder(tester, thinking: true);
    await tester.pump(const Duration(milliseconds: 300));

    await pumpBorder(tester, thinking: false);
    await tester.pumpAndSettle();

    expect(sweepPainter(), findsNothing);
  });

  testWidgets('never blocks the field underneath', (tester) async {
    var tapped = 0;
    await pumpBorder(
      tester,
      thinking: true,
      child: SizedBox(
        width: 200,
        height: 48,
        child: TextButton(
          onPressed: () => tapped++,
          child: const Text('champ'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('champ'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tapped, 1);
  });
}
