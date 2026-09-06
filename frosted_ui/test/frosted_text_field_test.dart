import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);

  Future<void> pump(WidgetTester tester, Widget field) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(body: field),
      ),
    );
  }

  group('FrostedTextField trailing', () {
    const Key marker = Key('trailing');

    testWidgets('hangs a widget where the trailing glyph would go', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const FrostedTextField(trailing: SizedBox(key: marker, width: 24)),
      );

      final double input = tester.getBottomRight(find.byType(TextField)).dx;
      expect(tester.getTopLeft(find.byKey(marker)).dx, greaterThan(input));
    });

    testWidgets('takes the slot over from the glyph', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const FrostedTextField(
          trailingIcon: Icons.close,
          trailing: SizedBox(key: marker, width: 24),
        ),
      );

      expect(find.byKey(marker), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('leaves the row alone when neither is given', (
      WidgetTester tester,
    ) async {
      await pump(tester, const FrostedTextField());

      expect(find.byKey(marker), findsNothing);
    });
  });

  group('FrostedTextField autofocus', () {
    testWidgets('takes focus on mount when set', (WidgetTester tester) async {
      await pump(tester, const FrostedTextField(autofocus: true));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).autofocus,
        isTrue,
      );
      expect(
        FocusScope.of(tester.element(find.byType(TextField))).hasFocus,
        isTrue,
      );
    });

    testWidgets('stays unfocused by default', (WidgetTester tester) async {
      await pump(tester, const FrostedTextField());
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).autofocus,
        isFalse,
      );
    });
  });
}
