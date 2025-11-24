import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/loans/viewmodels/loan_creation_viewmodel.dart';
import 'package:mybudget/core/enums/loan_enums.dart';

void main() {
  late LoanCreationViewModel viewModel;

  setUp(() {
    viewModel = LoanCreationViewModel();
  });

  test('Steps validation logic', () {
    expect(viewModel.currentStep, 0);
    expect(viewModel.canGoNext, false);

    viewModel.nameController.text = 'Loan A';
    expect(viewModel.canGoNext, false);

    viewModel.lenderController.text = 'Bank';
    viewModel.amountController.text = '10000';
    viewModel.setAccountId(1);

    expect(viewModel.canGoNext, true);

    viewModel.nextStep();
    expect(viewModel.currentStep, 1);

    expect(viewModel.canGoNext, false);

    viewModel.durationController.text = '12';

    expect(viewModel.canGoNext, true);
  });

  test('Financial calculations update in real-time', () {
    viewModel.amountController.text = '10000';
    viewModel.setDurationUnit(DurationUnit.months);
    viewModel.durationController.text = '12';
    viewModel.rateController.text = '0';

    expect(viewModel.totalMonthlyPayment, closeTo(833.33, 0.01));

    viewModel.rateController.text = '10';

    expect(viewModel.totalMonthlyPayment, closeTo(879.16, 0.01));

    viewModel.setInsuranceType(LoanInsuranceType.fixed);
    viewModel.insuranceValueController.text = '20';

    expect(viewModel.totalMonthlyPayment, closeTo(899.16, 0.01));
  });

  test('Input handling should handle commas', () {
    viewModel.amountController.text = '1000,50';
    expect(viewModel.amount, 1000.50);

    viewModel.rateController.text = '2,5';
    expect(viewModel.interestRate, 2.5);
  });

  test('Duration unit conversion', () {
    viewModel.durationController.text = '2';

    viewModel.setDurationUnit(DurationUnit.years);
    expect(viewModel.durationInMonths, 24);

    viewModel.setDurationUnit(DurationUnit.months);
    expect(viewModel.durationInMonths, 2);
  });
}
