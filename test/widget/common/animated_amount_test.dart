import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/common/widgets/animated_amount.dart';

void main() {
  Future<void> pumpAmount(WidgetTester tester, double amount) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedAmount(
            amount: amount,
            builder: (context, value) => Text(value.toStringAsFixed(2)),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the amount straight away on first build', (tester) async {
    await pumpAmount(tester, 120);

    expect(find.text('120.00'), findsOneWidget);
  });

  testWidgets('counts towards a new amount instead of jumping', (
    tester,
  ) async {
    await pumpAmount(tester, 100);
    await pumpAmount(tester, 200);

    await tester.pump(AnimatedAmount.duration * 0.5);
    final text = tester
        .widget<Text>(find.byType(Text))
        .data!;
    final displayed = double.parse(text);
    expect(displayed, greaterThan(100));
    expect(displayed, lessThan(200));

    await tester.pumpAndSettle();
    expect(find.text('200.00'), findsOneWidget);
  });

  testWidgets('a change mid-flight starts from where the count is', (
    tester,
  ) async {
    await pumpAmount(tester, 100);
    await pumpAmount(tester, 200);
    await tester.pump(AnimatedAmount.duration * 0.5);

    await pumpAmount(tester, 0);
    await tester.pump();
    final text = tester.widget<Text>(find.byType(Text)).data!;
    expect(double.parse(text), lessThan(200));

    await tester.pumpAndSettle();
    expect(find.text('0.00'), findsOneWidget);
  });
}
