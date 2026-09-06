import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<double> bottomOfSnackbar(
    WidgetTester tester, {
    double bottomInset = 0,
  }) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              hostContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    FrostedSnackbar.show(
      hostContext,
      message: 'Enregistré',
      bottomInset: bottomInset,
    );
    await tester.pumpAndSettle();

    final Size screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final double bottom =
        screen.height - tester.getBottomLeft(find.text('Enregistré')).dy;

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    return bottom;
  }

  testWidgets('sits above the bottom edge by default', (
    WidgetTester tester,
  ) async {
    expect(await bottomOfSnackbar(tester), greaterThan(0));
  });

  testWidgets('clears a floating bar when given its footprint', (
    WidgetTester tester,
  ) async {
    final double plain = await bottomOfSnackbar(tester);
    final double lifted = await bottomOfSnackbar(tester, bottomInset: 68);

    expect(lifted - plain, moreOrLessEquals(68, epsilon: 0.5));
  });
}
