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
      expect(updated.lenderName, loan.lenderName);
    });

    test('getAutomaticPaidAmount should calculate correctly', () {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1);
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

      expect(loan.getAutomaticPaidAmount(), 300.0);
    });

    test('getAutomaticStatus should return completed if fully paid', () {
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, 1, 1);
      final endDate = DateTime(now.year - 1, 12, 31);

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

      expect(loan.getAutomaticStatus(), LoanStatus.completed);
    });
  });
}
