import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/values/loan.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/loan_event_model.dart';
import 'package:mybudget/data/model/loan_model.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/provider/loan_queries.dart';
import 'package:mybudget/data/provider/loans_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;
  late int accountId;

  final DateTime now = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: now);
    accountId = app.accounts.add(
      AccountModel.create(name: 'Courant', bank: 'Boursorama'),
    );
  });

  tearDown(() => app.dispose());

  LoanNotifier loans() => app.container.read(loanProvider.notifier);

  Future<Loan> addLoan({
    String name = 'Prêt auto',
    double amount = 12000,
    double interestRate = 3.0,
    int duration = 24,
    DateTime? startDate,
  }) async {
    final DateTime start = startDate ?? DateTime(2026, 1, 5);
    await loans().addLoan(
      LoanModel.create(
        name: name,
        amount: amount,
        lenderName: 'Banque',
        accountId: accountId,
        dayOfMonth: 5,
        startDate: start,
        endDate: DateTime(start.year, start.month + duration, 5),
        interestRate: interestRate,
        duration: duration,
      ),
    );
    final List<Loan> all = await app.container.read(loanProvider.future);
    return all.firstWhere((Loan loan) => loan.name == name);
  }

  group('un emprunt créé', () {
    test('porte un échéancier de la durée demandée', () async {
      final Loan loan = await addLoan(duration: 24);

      expect(loan.installments, hasLength(24));
    });

    test(
      'a une mensualité constante et un capital restant décroissant',
      () async {
        final Loan loan = await addLoan();

        expect(loan.currentMonthlyPayment, greaterThan(0));
        expect(loan.remainingCapital, lessThan(loan.amount));
        expect(loan.remainingCapital, greaterThan(0));
      },
    );

    test('coûte plus cher que le capital emprunté', () async {
      final Loan loan = await addLoan(interestRate: 3.0);

      expect(loan.totalCost, greaterThan(0));
    });

    test('ne coûte rien de plus à taux zéro', () async {
      final Loan loan = await addLoan(interestRate: 0);

      expect(loan.totalCost, closeTo(0, 0.01));
    });

    test('est actif tant que la dernière échéance n\'est pas passée', () async {
      final Loan loan = await addLoan();

      expect(loan.isActive, isTrue);
      expect(loan.isCompleted, isFalse);
    });

    test('reçoit une date de fin dérivée de son échéancier', () async {
      await addLoan(duration: 24);

      final LoanModel stored = app.loans.getAll().single;

      expect(stored.endDate.year, 2028);
      expect(stored.endDate.month, 1);
    });
  });

  group('les agrégats', () {
    test('la mensualité totale additionne les emprunts actifs', () async {
      final Loan first = await addLoan(name: 'Prêt auto', amount: 12000);
      final Loan second = await addLoan(name: 'Prêt travaux', amount: 6000);

      expect(
        app.container.read(totalMonthlyLoanPaymentsProvider),
        closeTo(
          first.currentMonthlyPayment + second.currentMonthlyPayment,
          0.01,
        ),
      );
    });

    test('le capital restant total suit les emprunts actifs', () async {
      final Loan loan = await addLoan();

      expect(
        app.container.read(totalRemainingLoanAmountProvider),
        closeTo(loan.remainingCapital, 0.01),
      );
    });

    test('la mensualité pèse sur le solde du compte porteur', () async {
      final Loan loan = await addLoan();
      app.container.read(accountProvider);

      final double balance = app.container
          .read(accountProvider.notifier)
          .getAccountBalance(accountId);

      expect(balance, closeTo(-loan.currentMonthlyPayment, 0.01));
    });
  });

  group('un remboursement anticipé partiel', () {
    test('réduit le capital restant', () async {
      final Loan before = await addLoan();

      await loans().addEvent(
        LoanEventModel.create(
          loanId: before.id,
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 4, 5),
          amount: 3000,
        ),
      );

      final Loan after = (await app.container.read(loanProvider.future)).single;

      expect(after.remainingCapital, lessThan(before.remainingCapital));
    });

    test(
      'en réduisant la durée, garde la mensualité et raccourcit le prêt',
      () async {
        final Loan before = await addLoan();

        await loans().addEvent(
          LoanEventModel.create(
            loanId: before.id,
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2026, 4, 5),
            amount: 3000,
            reamortizationMode: ReamortizationMode.reduceDuration,
          ),
        );

        final Loan after = (await app.container.read(
          loanProvider.future,
        )).single;

        expect(after.remainingMonths, lessThan(before.remainingMonths));
      },
    );

    test('en réduisant la mensualité, garde la durée', () async {
      final Loan before = await addLoan();

      await loans().addEvent(
        LoanEventModel.create(
          loanId: before.id,
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 4, 5),
          amount: 3000,
          reamortizationMode: ReamortizationMode.reducePayment,
        ),
      );

      final Loan after = (await app.container.read(loanProvider.future)).single;

      expect(
        after.currentMonthlyPayment,
        lessThan(before.currentMonthlyPayment),
      );
    });

    test('est retrouvable sur son emprunt', () async {
      final Loan loan = await addLoan();

      await loans().addEvent(
        LoanEventModel.create(
          loanId: loan.id,
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 4, 5),
          amount: 3000,
        ),
      );

      expect(loans().eventsOf(loan.id), hasLength(1));
    });

    test('annulé, il rend son capital à l\'emprunt', () async {
      final Loan before = await addLoan();
      await loans().addEvent(
        LoanEventModel.create(
          loanId: before.id,
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 4, 5),
          amount: 3000,
        ),
      );
      final LoanEventModel event = app.loanEvents.getAll().single;

      await loans().deleteEvent(event);

      final Loan after = (await app.container.read(loanProvider.future)).single;

      expect(app.loanEvents.getAll(), isEmpty);
      expect(after.remainingCapital, closeTo(before.remainingCapital, 0.01));
    });
  });

  group('un remboursement anticipé total', () {
    test('solde l\'emprunt et le sort des actifs', () async {
      final Loan loan = await addLoan();

      await loans().addEvent(
        LoanEventModel.create(
          loanId: loan.id,
          type: LoanEventType.earlyRepaymentTotal,
          date: DateTime(2026, 4, 5),
          amount: loan.remainingCapital,
        ),
      );

      final Loan after = (await app.container.read(loanProvider.future)).single;

      expect(after.isCompleted, isTrue);
      expect(app.container.read(activeLoansProvider), isEmpty);
    });

    test('cesse de peser sur le solde du compte', () async {
      final Loan loan = await addLoan();

      await loans().addEvent(
        LoanEventModel.create(
          loanId: loan.id,
          type: LoanEventType.earlyRepaymentTotal,
          date: DateTime(2026, 4, 5),
          amount: loan.remainingCapital,
        ),
      );
      app.container.read(accountProvider);

      expect(
        app.container
            .read(accountProvider.notifier)
            .getAccountBalance(accountId),
        0,
      );
    });
  });

  group('la suppression d\'un emprunt', () {
    test('emporte ses remboursements anticipés', () async {
      final Loan loan = await addLoan();
      await loans().addEvent(
        LoanEventModel.create(
          loanId: loan.id,
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 4, 5),
          amount: 3000,
        ),
      );

      await loans().deleteLoan(loan.id);

      expect(app.loans.getAll(), isEmpty);
      expect(app.loanEvents.getAll(), isEmpty);
    });
  });
}
