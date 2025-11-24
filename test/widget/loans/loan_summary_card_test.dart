import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/loans/widgets/loan_summary_card.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Scaffold(
        body: LoanSummaryCard(
          totalDebt: 10000,
          monthlyPayment: 500,
          progress: 0.5,
          activeLoanCount: 2,
          remainingCost: 200,
        ),
      ),
    );
  }

  testWidgets('LoanSummaryCard displays formatted values correctly', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.textContaining('500,00'), findsOneWidget);
    expect(find.textContaining('10\u202F000,00'), findsOneWidget);
    expect(find.textContaining('200,00'), findsOneWidget);
    expect(find.text('2 actifs'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('LoanSummaryCard shows info dialog when help icon is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final helpIcons = find.byIcon(Icons.help_outline);
    expect(helpIcons, findsNWidgets(2));

    await tester.tap(helpIcons.first);
    await tester.pumpAndSettle();

    expect(find.text('Coût du crédit'), findsNWidgets(2));
    expect(find.textContaining('intérêts et des assurances'), findsOneWidget);

    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();

    expect(find.text('Coût du crédit'), findsOneWidget);
  });
}
