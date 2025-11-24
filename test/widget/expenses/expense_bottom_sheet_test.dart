import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';

void main() {
  testWidgets('ExpenseBottomSheet validation and submission', (tester) async {
    ExpenseModel? submittedExpense;

    final accounts = [
      AccountModel.create(name: 'Main Account', bank: 'Bank A')..id = 1,
    ];
    final categories = [
      CategoryModel.create(name: 'Food', icon: 'fastfood')..id = 10,
      CategoryModel.create(name: 'Transport', icon: 'car')..id = 20,
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ExpenseBottomSheet(
                accounts: accounts,
                categories: categories,
                onCancel: () {},
                onSubmit: (expense) {
                  submittedExpense = expense;
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Informations'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('Montant'), findsOneWidget);

    await tester.tap(find.text('Ajouter'));
    await tester.pump();

    expect(submittedExpense, isNull);

    final textFields = find.byType(TextField);
    expect(textFields, findsAtLeastNWidgets(2));

    await tester.enterText(textFields.at(0), 'Burger King');

    await tester.enterText(textFields.at(1), '15.50');

    final submitButton = find.text('Ajouter');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(submittedExpense, isNotNull);
    expect(submittedExpense!.name, 'Burger King');
    expect(submittedExpense!.amount, 15.50);
    expect(submittedExpense!.categoryId, 10);
    expect(submittedExpense!.accountId, 1);
  });
}
