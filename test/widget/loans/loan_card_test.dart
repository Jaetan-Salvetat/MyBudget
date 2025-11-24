import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/loans/widgets/loan_card.dart';
import 'package:mybudget/models/loan_model.dart';

void main() {
  testWidgets('LoanCard displays correct information and handles tap', (
    tester,
  ) async {
    bool tapped = false;

    final loan = LoanModel.create(
      name: 'Test Loan',
      amount: 12000,
      monthlyPayment: 1000,
      accountId: 1,
      interestRate: 0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 365)),
      dayOfMonth: 1,
      lenderName: 'Bank',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoanCard(
            loan: loan,
            accountName: 'Main Account',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Loan'), findsOneWidget);
    expect(find.text('Main Account'), findsOneWidget);

    expect(find.textContaining('/mois'), findsOneWidget);
    expect(find.textContaining('1\u202F000,00'), findsAtLeastNWidgets(1));

    expect(find.textContaining('Capital :'), findsOneWidget);

    expect(find.textContaining('mois restants'), findsOneWidget);

    await tester.tap(find.byType(LoanCard));
    expect(tapped, true);
  });
}
