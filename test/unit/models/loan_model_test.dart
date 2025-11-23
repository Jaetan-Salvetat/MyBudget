import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/loan_model.dart';

void main() {
  group('LoanModel', () {
    test('should create a valid instance', () {
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2024, 1, 1);
      final loan = LoanModel.create(
        name: 'Car Loan',
        amount: 12000.0,
        lenderName: 'Bank',
        dayOfMonth: 5,
        startDate: startDate,
        endDate: endDate,
        accountId: 1,
        monthlyPayment: 1000.0,
      );

      expect(loan.name, 'Car Loan');
      expect(loan.amount, 12000.0);
      expect(loan.lenderName, 'Bank');
      expect(loan.dayOfMonth, 5);
      expect(loan.startDate, startDate);
      expect(loan.endDate, endDate);
      expect(loan.accountId, 1);
      expect(loan.monthlyPayment, 1000.0);
    });

    test('copyWith should return a new instance with updated values', () {
      final loan = LoanModel.create(
        name: 'Original',
        amount: 1000.0,
        lenderName: 'Lender',
        dayOfMonth: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        accountId: 1,
        monthlyPayment: 100.0,
      );

      final updated = loan.copyWith(name: 'Updated', amount: 2000.0);

      expect(updated.name, 'Updated');
      expect(updated.amount, 2000.0);
      expect(updated.lenderName, loan.lenderName); // Unchanged
    });

    test('getAutomaticPaidAmount should calculate correctly', () {
      // Start date: 1st Jan 2023
      // Monthly payment: 100
      // Current date (mocked conceptually): 1st Mar 2023 -> 2 months passed (Jan, Feb)
      // Note: Since getAutomaticPaidAmount uses DateTime.now(), we can't easily mock time without a wrapper or library.
      // For this unit test, we'll test the logic by setting start date relative to now.

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1); // 2 months ago
      final endDate = DateTime(now.year + 1, 1, 1);

      final loan = LoanModel.create(
        name: 'Test',
        amount: 1000.0,
        lenderName: 'Lender',
        dayOfMonth: 1,
        startDate: startDate,
        endDate: endDate,
        accountId: 1,
        monthlyPayment: 100.0,
      );

      // 2 months passed (Month-2, Month-1) + current month if day >= 1
      // If today is >= 1st, then 3 payments (Month-2, Month-1, Current)
      // If today is < 1st (impossible since 1 is min), always 3 payments.
      // Wait, let's trace:
      // startYearMonth = Y*12 + M-2
      // nowYearMonth = Y*12 + M
      // diff = 2
      // daysPassed = now.day >= 1 ? 1 : 0 -> 1
      // total months = 2 + 1 = 3

      expect(loan.getAutomaticPaidAmount(), 300.0);
    });

    test('getAutomaticStatus should return completed if fully paid', () {
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, 1, 1);
      final endDate = DateTime(now.year - 1, 12, 31); // Ended in past

      final loan = LoanModel.create(
        name: 'Test',
        amount: 1200.0,
        lenderName: 'Lender',
        dayOfMonth: 1,
        startDate: startDate,
        endDate: endDate,
        accountId: 1,
        monthlyPayment: 100.0,
      );

      // Should be fully paid
      expect(loan.getAutomaticStatus(), LoanStatus.completed);
    });
  });
}
