import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/loan_model.dart';

void main() {
  group('LoanModel Financial Logic', () {
    test(
      'totalCost should be calculated correctly (Total Payments - Amount)',
      () {
        final loan = LoanModel(
          name: 'Test Loan',
          amount: 10000,
          monthlyPayment: 1000,
          duration: 12,
          interestRate: 0,
          lenderName: 'Bank',
          accountId: 1,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2025, 1, 1),
          dayOfMonth: 1,
        );

        expect(loan.totalCost, 2000.0);
      },
    );

    test(
      'totalCost should handle legacy loans with duration 0 by calculating real duration',
      () {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 11, 1);

        final loan = LoanModel(
          name: 'Legacy Loan',
          amount: 1000,
          monthlyPayment: 110,
          duration: 0,
          lenderName: 'Bank',
          accountId: 1,
          startDate: startDate,
          endDate: endDate,
          dayOfMonth: 1,
        );

        expect(loan.totalCost, 100.0);
      },
    );

    test('remainingCapital should respect amortization logic (Not Linear)', () {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 6, now.day);
      final endDate = DateTime(now.year, now.month + 6, now.day);

      final loan = LoanModel(
        name: 'Amortization Test',
        amount: 12000,
        monthlyPayment: 1100,
        duration: 12,
        interestRate: 10,
        lenderName: 'Bank',
        accountId: 1,
        startDate: startDate,
        endDate: endDate,
        dayOfMonth: 1,
      );

      expect(loan.remainingCapital, lessThan(12000));
      expect(loan.remainingCapital, greaterThan(0));

      expect(loan.getProgressPercentage(), inInclusiveRange(0.4, 0.6));
    });

    test('isCompleted should return true if end date is passed', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 400));
      final loan = LoanModel(
        name: 'Past Loan',
        amount: 5000,
        monthlyPayment: 100,
        duration: 12,
        lenderName: 'Bank',
        accountId: 1,
        startDate: pastDate,
        endDate: pastDate.add(const Duration(days: 300)),
        dayOfMonth: 1,
      );

      expect(loan.isCompleted(), isTrue);
      expect(loan.remainingCapital, 0.0);
    });
  });
}
