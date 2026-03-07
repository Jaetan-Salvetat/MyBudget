import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late LoanViewModel viewModel;
  late MockLoanRepository mockRepository;

  setUp(() {
    mockRepository = MockLoanRepository();
    when(() => mockRepository.getAll()).thenReturn([]);
    viewModel = LoanViewModel(mockRepository);
  });

  test(
    'getTotalActiveInitialAmount should sum up amounts of active loans',
    () async {
      final loan1 = LoanModel(
        name: 'Loan 1',
        amount: 10000,
        duration: 12,
        interestRate: 5,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        dayOfMonth: 1,
        lenderName: 'Bank',
        accountId: 1,
      );

      final loan2 = LoanModel(
        name: 'Loan 2',
        amount: 5000,
        duration: 12,
        interestRate: 5,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        dayOfMonth: 1,
        lenderName: 'Bank',
        accountId: 1,
      );

      when(() => mockRepository.getAll()).thenReturn([loan1, loan2]);

      await viewModel.loadLoans();

      expect(viewModel.getTotalActiveInitialAmount(), 15000.0);
    },
  );

  test('getActiveLoans should filter out completed loans', () async {
    final activeLoan = LoanModel(
      name: 'Active',
      amount: 1000,
      duration: 12,
      interestRate: 5,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 365)),
      dayOfMonth: 1,
      lenderName: 'Bank',
      accountId: 1,
    );

    final completedLoan = LoanModel(
      name: 'Completed',
      amount: 1000,
      duration: 12,
      interestRate: 5,
      startDate: DateTime.now().subtract(const Duration(days: 700)),
      endDate: DateTime.now().subtract(const Duration(days: 365)),
      dayOfMonth: 1,
      lenderName: 'Bank',
      accountId: 1,
    );

    when(() => mockRepository.getAll()).thenReturn([activeLoan, completedLoan]);

    await viewModel.loadLoans();

    final active = viewModel.getActiveLoans();
    expect(active.length, 1);
    expect(active.first.name, 'Active');
  });

  test('getTotalRemainingCost should aggregate cost correctly', () async {
    final loan = LoanModel(
      name: 'Cost Test',
      amount: 1000,
      duration: 10,
      interestRate: 5,
      lenderName: 'Bank',
      accountId: 1,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 300)),
      dayOfMonth: 1,
    );

    when(() => mockRepository.getAll()).thenReturn([loan]);
    await viewModel.loadLoans();

    final cost = viewModel.getTotalRemainingCost();
    expect(cost, greaterThan(0));
  });

  test('should set error state when repository fails', () async {
    when(() => mockRepository.getAll()).thenThrow(Exception('DB Error'));

    await viewModel.loadLoans();

    expect(viewModel.error, contains('DB Error'));
    expect(viewModel.isLoading, false);
  });
}
