import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/ui/loans/providers/loan_creation_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    return ProviderContainer();
  }

  test('Steps validation logic', () {
    final container = makeContainer();
    addTearDown(container.dispose);

    final notifier = container.read(loanCreationProvider.notifier);

    expect(container.read(loanCreationProvider).currentStep, 0);
    expect(container.read(loanCreationProvider).canGoNext, false);

    notifier.setName('Loan A');
    expect(container.read(loanCreationProvider).canGoNext, false);

    notifier.setLenderName('Bank');
    notifier.setAmount('10000');
    notifier.setAccountId(1);

    expect(container.read(loanCreationProvider).canGoNext, true);

    notifier.nextStep();
    expect(container.read(loanCreationProvider).currentStep, 1);

    expect(container.read(loanCreationProvider).canGoNext, false);

    notifier.setDurationValue('12');

    expect(container.read(loanCreationProvider).canGoNext, true);
  });

  test('Financial calculations update in real-time', () {
    final container = makeContainer();
    addTearDown(container.dispose);

    final notifier = container.read(loanCreationProvider.notifier);

    notifier.setAmount('10000');
    notifier.setDurationUnit(DurationUnit.months);
    notifier.setDurationValue('12');
    notifier.setInterestRate('0');

    expect(
      container.read(loanCreationProvider).totalMonthlyPayment,
      closeTo(833.33, 0.01),
    );

    notifier.setInterestRate('10');

    expect(
      container.read(loanCreationProvider).totalMonthlyPayment,
      closeTo(879.16, 0.01),
    );

    notifier.setInsuranceType(LoanInsuranceType.fixed);
    notifier.setInsuranceValue('20');

    expect(
      container.read(loanCreationProvider).totalMonthlyPayment,
      closeTo(899.16, 0.01),
    );
  });

  test('Input handling should handle commas', () {
    final container = makeContainer();
    addTearDown(container.dispose);

    final notifier = container.read(loanCreationProvider.notifier);

    notifier.setAmount('1000,50');
    expect(container.read(loanCreationProvider).amount, 1000.50);

    notifier.setInterestRate('2,5');
    expect(container.read(loanCreationProvider).interestRate, 2.5);
  });

  test('Duration unit conversion', () {
    final container = makeContainer();
    addTearDown(container.dispose);

    final notifier = container.read(loanCreationProvider.notifier);

    notifier.setDurationValue('2');

    notifier.setDurationUnit(DurationUnit.years);
    expect(container.read(loanCreationProvider).durationInMonths, 24);

    notifier.setDurationUnit(DurationUnit.months);
    expect(container.read(loanCreationProvider).durationInMonths, 2);
  });
}
