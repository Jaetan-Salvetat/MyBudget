import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots and shows the foundations entry',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FrostedExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Foundations'), findsOneWidget);
  });
}
