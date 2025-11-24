import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/revenue_model.dart';

void main() {
  final List<AccountModel> accounts = [
    AccountModel.create(name: 'Main Account', bank: 'Bank')..id = 1,
  ];

  Widget createWidgetUnderTest({
    Function(RevenueModel)? onSubmit,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RevenueBottomSheet(
          accounts: accounts,
          onSubmit: onSubmit ?? (_) {},
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  group('RevenueBottomSheet', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Informations'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Montant'), findsOneWidget);
      expect(find.text('Compte'), findsOneWidget);
      expect(find.text('Planification'), findsOneWidget);
      expect(find.text('Ajouter'), findsOneWidget);
    });

    testWidgets('calls onSubmit with valid data', (tester) async {
      RevenueModel? submittedRevenue;
      await tester.pumpWidget(
        createWidgetUnderTest(
          onSubmit: (revenue) => submittedRevenue = revenue,
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'Salary');

      await tester.enterText(find.byType(TextField).at(1), '2000.0');

      final submitButton = find.text('Ajouter');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(submittedRevenue, isNotNull);
      expect(submittedRevenue!.name, 'Salary');
      expect(submittedRevenue!.amount, 2000.0);
      expect(submittedRevenue!.accountId, 1);
      expect(submittedRevenue!.isRegular, true);
    });
  });
}
