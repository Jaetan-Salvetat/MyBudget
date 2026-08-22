import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
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

  group('loan purpose', () {
    ProviderContainer containerWithAmount(String amount) {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(loanCreationProvider.notifier).setAmount(amount);
      return container;
    }

    test('defaults to the neutral purpose and the threshold regime', () {
      final state = containerWithAmount('20000').read(loanCreationProvider);

      expect(state.purpose, LoanPurpose.other);
      expect(state.effectiveRegime, CreditRegime.consumer);
    });

    test('derives the regime from the selected purpose', () {
      final container = containerWithAmount('20000');
      container.read(loanCreationProvider.notifier).setPurpose(
        LoanPurpose.mortgage,
      );

      expect(
        container.read(loanCreationProvider).effectiveRegime,
        CreditRegime.mortgage,
      );
    });

    test('preselects an in fine bridge loan without an indemnity', () {
      final container = containerWithAmount('200000');
      container.read(loanCreationProvider.notifier).setPurpose(
        LoanPurpose.bridge,
      );

      final state = container.read(loanCreationProvider);
      expect(state.repaymentType, LoanRepaymentType.inFine);
      expect(state.hasIndemnityClause, isFalse);
    });

    test('preselects an upfront first payment on an instalment plan', () {
      final container = containerWithAmount('1000');
      container.read(loanCreationProvider.notifier).setPurpose(
        LoanPurpose.instalmentPlan,
      );

      expect(
        container.read(loanCreationProvider).immediateFirstPayment,
        isTrue,
      );
    });

    test('never reverts a setting the user already made', () {
      final container = containerWithAmount('200000');
      final notifier = container.read(loanCreationProvider.notifier);

      notifier.setPurpose(LoanPurpose.bridge);
      notifier.setPurpose(LoanPurpose.car);

      final state = container.read(loanCreationProvider);
      expect(state.repaymentType, LoanRepaymentType.inFine);
      expect(state.hasIndemnityClause, isFalse);
      expect(state.effectiveRegime, CreditRegime.consumer);
    });

    test('carries the purpose into the persisted model', () {
      final container = containerWithAmount('20000');
      final notifier = container.read(loanCreationProvider.notifier);

      notifier.setName('Clio');
      notifier.setLenderName('Banque');
      notifier.setAccountId(1);
      notifier.setDurationValue('48');
      notifier.setPurpose(LoanPurpose.car);

      final model = notifier.createLoanModel();

      expect(model.purpose, LoanPurpose.car);
      expect(model.regime, CreditRegime.consumer);
    });
  });
}
