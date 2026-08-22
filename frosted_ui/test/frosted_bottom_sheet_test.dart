import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<void> pump(WidgetTester tester, Widget sheet) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(body: sheet),
      ),
    );
  }

  group('FrostedBottomSheet height', () {
    testWidgets('a taller-than-viewport child is capped, not overflowed', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.dark(seedColor: seed),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FrostedBottomSheet(
                title: 'Catégorie',
                child: ListView(
                  shrinkWrap: true,
                  children: List<Widget>.generate(
                    40,
                    (int i) => SizedBox(height: 48, child: Text('row $i')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FrostedBottomSheet)).height,
        lessThanOrEqualTo(600),
      );
    });
  });

  group('FrostedBottomSheet title', () {
    testWidgets('renders the title above the content', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const FrostedBottomSheet(
          title: 'Nouvelle dépense',
          child: Text('contenu'),
        ),
      );

      expect(find.text('Nouvelle dépense'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Nouvelle dépense')).dy,
        lessThan(tester.getTopLeft(find.text('contenu')).dy),
      );
    });

    testWidgets('renders nothing extra without a title', (
      WidgetTester tester,
    ) async {
      await pump(tester, const FrostedBottomSheet(child: Text('contenu')));

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('styles the title with the titleLarge role', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const FrostedBottomSheet(title: 'Titre', child: SizedBox()),
      );

      final Text title = tester.widget<Text>(find.text('Titre'));

      expect(title.style!.fontSize, FrostedTypeScale.titleLarge.fontSize);
      expect(title.style!.fontWeight, FrostedTypeScale.titleLarge.fontWeight);
    });
  });
}
