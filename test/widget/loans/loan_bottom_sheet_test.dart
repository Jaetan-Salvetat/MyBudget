import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/loans/widgets/loan_bottom_sheet.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';

void main() {
  final List<AccountModel> accounts = [
    AccountModel.create(name: 'Main Account', bank: 'Bank')..id = 1,
  ];

  Widget createWidgetUnderTest({
    Function(LoanModel)? onSubmit,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LoanBottomSheet(
          accounts: accounts,
          onSubmit: onSubmit ?? (_) {},
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  group('LoanBottomSheet', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Informations'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Prêteur'), findsOneWidget);
      expect(find.text('Montant total'), findsOneWidget);
      expect(find.text('Mensualité'), findsOneWidget);
      expect(find.text('Calendrier'), findsOneWidget);
      expect(find.text('Compte'), findsOneWidget);
      expect(find.text('Ajouter'), findsOneWidget);
    });

    testWidgets('calls onSubmit with valid data', (tester) async {
      LoanModel? submittedLoan;
      await tester.pumpWidget(
        createWidgetUnderTest(onSubmit: (loan) => submittedLoan = loan),
      );

      // Enter Name
      await tester.enterText(find.byType(TextField).at(0), 'Car Loan');

      // Enter Lender
      await tester.enterText(find.byType(TextField).at(1), 'Bank');

      // Enter Amount
      await tester.enterText(find.byType(TextField).at(2), '12000.0');

      // Enter Monthly Payment
      await tester.enterText(find.byType(TextField).at(3), '1000.0');

      // Tap Submit
      final submitButton = find.text('Ajouter');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(submittedLoan, isNotNull);
      expect(submittedLoan!.name, 'Car Loan');
      expect(submittedLoan!.lenderName, 'Bank');
      expect(submittedLoan!.amount, 12000.0);
      expect(submittedLoan!.monthlyPayment, 1000.0);
      expect(submittedLoan!.accountId, 1);
    });
  });
}
