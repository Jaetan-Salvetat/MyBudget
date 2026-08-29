import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/capture/widgets/journal_landing.dart';

void main() {
  const double lineHeight = 60;

  Future<void> pumpLanding(
    WidgetTester tester, {
    bool animate = true,
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: !animate),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topCenter,
            child: JournalLanding(
              child: SizedBox(height: lineHeight, width: 200),
            ),
          ),
        ),
      ),
    );
  }

  double landingHeight(WidgetTester tester) =>
      tester.getSize(find.byType(JournalLanding)).height;

  testWidgets('le journal ouvre le créneau depuis une hauteur nulle', (
    tester,
  ) async {
    await pumpLanding(tester);

    expect(landingHeight(tester), lessThan(1));

    await tester.pump(JournalLanding.duration);

    expect(landingHeight(tester), lineHeight);
  });

  testWidgets('le créneau s\'ouvre sans à-coup, pas d\'un bloc', (
    tester,
  ) async {
    await pumpLanding(tester);
    await tester.pump(const Duration(milliseconds: 120));

    final opened = landingHeight(tester);

    expect(opened, greaterThan(0));
    expect(opened, lessThan(lineHeight));
  });

  testWidgets('la ligne monte par en dessous, du côté de la saisie', (
    tester,
  ) async {
    await pumpLanding(tester);
    await tester.pump(const Duration(milliseconds: 80));

    final shift = tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(JournalLanding),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .getTranslation()
        .y;

    expect(shift, greaterThan(0));
  });

  testWidgets('sans animations, la ligne est posée dès la première frame', (
    tester,
  ) async {
    await pumpLanding(tester, animate: false);

    expect(landingHeight(tester), lineHeight);
  });
}
