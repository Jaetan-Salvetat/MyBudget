import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

const String message = 'Attention';

Future<void> pumpBanner(
  WidgetTester tester, {
  required FrostedBannerTone tone,
  required Brightness brightness,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark
          ? FrostedTheme.dark(seedColor: const Color(0xFF2A55D3))
          : FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
      home: Scaffold(
        body: FrostedBanner(message: message, tone: tone),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color surfaceOf(WidgetTester tester) {
  final Container container = tester.widget<Container>(
    find
        .ancestor(of: find.text(message), matching: find.byType(Container))
        .first,
  );
  return ((container.decoration! as BoxDecoration).color)!;
}

void main() {
  testWidgets('l\'information emprunte la couleur secondaire du thème', (
    WidgetTester tester,
  ) async {
    await pumpBanner(
      tester,
      tone: FrostedBannerTone.info,
      brightness: Brightness.light,
    );

    final ColorScheme colors = Theme.of(
      tester.element(find.text(message)),
    ).colorScheme;

    expect(surfaceOf(tester), colors.secondaryContainer);
  });

  testWidgets('l\'avertissement se distingue de l\'information', (
    WidgetTester tester,
  ) async {
    await pumpBanner(
      tester,
      tone: FrostedBannerTone.warning,
      brightness: Brightness.light,
    );

    expect(surfaceOf(tester), FrostedBanner.warningSurfaceLight);
  });

  testWidgets('l\'avertissement s\'adapte au thème sombre', (
    WidgetTester tester,
  ) async {
    await pumpBanner(
      tester,
      tone: FrostedBannerTone.warning,
      brightness: Brightness.dark,
    );

    expect(surfaceOf(tester), FrostedBanner.warningSurfaceDark);
  });
}
