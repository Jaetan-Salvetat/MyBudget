import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';

void main() {
  Widget createWidgetUnderTest({
    Function(String, String)? onSubmit,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AccountBottomSheet(
          onSubmit: onSubmit ?? (_, __) {},
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  group('AccountBottomSheet', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Nom du compte'), findsOneWidget);
      expect(find.text('Nom de la banque'), findsOneWidget);
      expect(find.text('Ajouter'), findsOneWidget);
    });

    testWidgets('calls onSubmit with valid data', (tester) async {
      String? submittedName;
      String? submittedBank;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onSubmit: (name, bank) {
            submittedName = name;
            submittedBank = bank;
          },
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'Main Account');

      await tester.enterText(find.byType(TextField).at(1), 'Bank A');
      await tester.pumpAndSettle();

      final submitButton = find.text('Ajouter');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(submittedName, 'Main Account');
      expect(submittedBank, 'Bank A');
    });
  });
}
