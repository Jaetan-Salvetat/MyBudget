import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/ui/loans/widgets/loan_progress_section.dart';
import 'package:mybudget/models/loan_model.dart';

void main() {
  final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  testWidgets('LoanProgressSection displays correct financial details', (
    tester,
  ) async {
    final loan = LoanModel.create(
      name: 'Test Loan',
      amount: 12000,
      monthlyPayment: 1000,
      accountId: 1,
      startDate: DateTime.now().subtract(const Duration(days: 180)),
      endDate: DateTime.now().add(const Duration(days: 180)),
      dayOfMonth: 1,
      interestRate: 0,
      lenderName: 'Bank Test',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoanProgressSection(loan: loan, formatter: formatter),
        ),
      ),
    );

    expect(find.textContaining('1\u202F000,00'), findsOneWidget);
    expect(find.textContaining('/mois'), findsOneWidget);

    expect(find.text('Capital remboursé'), findsOneWidget);
    expect(find.text('Capital restant'), findsOneWidget);
    expect(find.text('Progression'), findsOneWidget);

    expect(find.textContaining('mois restants'), findsOneWidget);

    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    expect(find.textContaining('%'), findsOneWidget);
  });
}
