import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/screens/loan_edit_screen.dart';

import '../../helpers/loan_test_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final account = AccountModel.create(name: 'Courant', bank: 'Banque')..id = 1;

  Loan buildLoan() {
    return buildTestLoan(
      LoanModel.create(
        name: 'Prêt Test',
        amount: 10000,
        lenderName: 'Banque Test',
        accountId: account.id,
        dayOfMonth: 15,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2025, 1, 1),
        interestRate: 5.0,
        duration: 12,
        repaymentType: LoanRepaymentType.amortizable,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.fixed,
        insuranceValue: 25.0,
        insuranceCalculationMode: InsuranceCalculationMode.initialCapital,
      ),
    );
  }

  Future<LoanModel? Function()> pushForm(WidgetTester tester) async {
    LoanModel? submitted;
    late BuildContext pageContext;

    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    unawaited(
      LoanEditScreen.push(
        context: pageContext,
        loan: buildLoan(),
        accounts: [account],
      ).then((value) => submitted = value),
    );
    await tester.pumpAndSettle();

    return () => submitted;
  }

  testWidgets('pops the updated loan back to the caller', (
    WidgetTester tester,
  ) async {
    final submitted = await pushForm(tester);

    await tester.enterText(find.byType(TextField).first, 'Prêt Immo');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(submitted()?.name, 'Prêt Immo');
    expect(find.byType(LoanEditScreen), findsNothing);
  });

  testWidgets('pops nothing when the user backs out', (
    WidgetTester tester,
  ) async {
    final submitted = await pushForm(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(submitted(), isNull);
    expect(find.byType(LoanEditScreen), findsNothing);
  });
}
