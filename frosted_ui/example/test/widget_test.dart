import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots and exposes the Foundations destination',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FrostedExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Foundations'), findsWidgets);
    expect(find.text('Type scale'.toUpperCase()), findsOneWidget);
  });
}
