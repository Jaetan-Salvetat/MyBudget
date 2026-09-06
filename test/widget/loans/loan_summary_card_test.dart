import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/percent_formatter.dart';
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
    expect(find.textContaining('10 000'), findsOneWidget);
    expect(find.textContaining('200'), findsWidgets);
    expect(find.text('· 2 actifs'), findsOneWidget);
    expect(find.text(PercentFormatter.formatWhole(50)), findsOneWidget);
    expect(find.text('Capital amorti'), findsOneWidget);
    expect(find.text('Capital restant'), findsOneWidget);
    expect(find.text('Coût restant'), findsOneWidget);
  });
}
