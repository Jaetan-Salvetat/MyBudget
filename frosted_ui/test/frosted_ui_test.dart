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
}
