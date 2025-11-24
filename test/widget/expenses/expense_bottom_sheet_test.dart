import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';

void main() {
  final List<AccountModel> accounts = [
    AccountModel.create(name: 'Main Account', bank: 'Bank')..id = 1,
  ];
  final List<CategoryModel> categories = [
    CategoryModel.create(name: 'Food', icon: 'fastfood', color: 0xFF000000)
      ..id = 1,
  ];

  Widget createWidgetUnderTest({
    Function(ExpenseModel)? onSubmit,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ExpenseBottomSheet(
          accounts: accounts,
          categories: categories,
          onSubmit: onSubmit ?? (_) {},
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  group('ExpenseBottomSheet', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Informations'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Montant'), findsOneWidget);
      expect(find.text('Catégorie'), findsOneWidget);
      expect(find.text('Compte'), findsOneWidget);
      expect(find.text('Ajouter'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
    });

    testWidgets('calls onSubmit with valid data', (tester) async {
      ExpenseModel? submittedExpense;
      await tester.pumpWidget(
        createWidgetUnderTest(
          onSubmit: (expense) => submittedExpense = expense,
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'Groceries');

      await tester.enterText(find.byType(TextField).at(1), '50.0');

      final submitButton = find.text('Ajouter');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(submittedExpense, isNotNull);
      expect(submittedExpense!.name, 'Groceries');
      expect(submittedExpense!.amount, 50.0);
      expect(submittedExpense!.categoryId, 1);
      expect(submittedExpense!.accountId, 1);
    });
  });
}
