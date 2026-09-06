import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/providers/loan_payoff_provider.dart';

import '../../helpers/loan_test_factory.dart';

void main() {
  Loan loanOf() {
    final model = LoanModel.create(
      name: 'Prêt',
      amount: 12000,
      lenderName: 'Banque',
      accountId: 1,
      dayOfMonth: 5,
      startDate: DateTime(2026, 1, 5),
      endDate: DateTime(2027, 1, 5),
      interestRate: 0,
      duration: 12,
    )..id = 7;

    return buildTestLoan(model, asOf: DateTime(2026, 6, 20));
  }

  ProviderContainer containerOf() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to settling the loan at the next installment', () {
    final loan = loanOf();
    final state = containerOf().read(loanPayoffProvider(loan));

    expect(state.type, LoanEventType.earlyRepaymentTotal);
    expect(state.date, DateTime(2026, 7, 5));
    expect(state.isValid, isTrue);
    expect(state.quote!.repaidCapital, closeTo(6000, 0.01));
  });

  test('is invalid until a partial repayment has an amount', () {
    final loan = loanOf();
    final container = containerOf();
    final notifier = container.read(loanPayoffProvider(loan).notifier);

    notifier.setType(LoanEventType.earlyRepaymentPartial);
    expect(container.read(loanPayoffProvider(loan)).isValid, isFalse);

    notifier.setAmount('2000');
    expect(container.read(loanPayoffProvider(loan)).isValid, isTrue);
  });

  test('requotes when the reamortization mode changes', () {
    final loan = loanOf();
    final container = containerOf();
    final notifier = container.read(loanPayoffProvider(loan).notifier);

    notifier.setType(LoanEventType.earlyRepaymentPartial);
    notifier.setAmount('2000');
    final shortened = container.read(loanPayoffProvider(loan)).quote!;

    notifier.setReamortizationMode(ReamortizationMode.reducePayment);
    final lowered = container.read(loanPayoffProvider(loan)).quote!;

    expect(shortened.monthsSaved, greaterThan(0));
    expect(lowered.monthsSaved, 0);
    expect(lowered.newMonthlyPayment, lessThan(shortened.newMonthlyPayment));
  });

  test('builds a persistable event carrying the loan id', () {
    final loan = loanOf();
    final container = containerOf();
    final notifier = container.read(loanPayoffProvider(loan).notifier);

    notifier.setType(LoanEventType.earlyRepaymentPartial);
    notifier.setAmount('1500');
    notifier.setExemption(EarlyRepaymentExemption.death);

    final event = container.read(loanPayoffProvider(loan)).toEventModel();

    expect(event.loanId, 7);
    expect(event.type, LoanEventType.earlyRepaymentPartial);
    expect(event.amount, 1500);
    expect(event.exemption, EarlyRepaymentExemption.death);
    expect(event.date, DateTime(2026, 7, 5));
  });
}
