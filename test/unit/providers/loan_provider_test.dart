import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/entities/loan.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

void main() {
  late MockLoanRepository mockRepository;
  late MockLoanEventRepository mockLoanEventRepo;

  setUp(() {
    mockRepository = MockLoanRepository();
    mockLoanEventRepo = MockLoanEventRepository();
    when(() => mockLoanEventRepo.getAll()).thenReturn([]);
    when(() => mockRepository.getAll()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        loanRepositoryProvider.overrideWithValue(mockRepository),
        loanEventRepositoryProvider.overrideWithValue(mockLoanEventRepo),
      ],
    );
  }

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

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(loanProvider.future);

      expect(
        container.read(loanProvider.notifier).getTotalActiveInitialAmount(),
        15000.0,
      );
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

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(loanProvider.future);

    final active = container.read(loanProvider.notifier).getActiveLoans();
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

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(loanProvider.future);

    final cost = container.read(loanProvider.notifier).getTotalRemainingCost();
    expect(cost, greaterThan(0));
  });

  test('getTotalActiveInitialAmount with empty list returns 0.0', () async {
    when(() => mockRepository.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(loanProvider.future);

    expect(
      container.read(loanProvider.notifier).getTotalActiveInitialAmount(),
      0.0,
    );
  });

  test(
    'getCompletedLoans returns only loans with endDate in the past',
    () async {
      final activeLoan = LoanModel(
        name: 'Active',
        amount: 1000,
        duration: 12,
        interestRate: 0,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 335)),
        dayOfMonth: 1,
        lenderName: 'Bank',
        accountId: 1,
      );
      final completedLoan = LoanModel(
        name: 'Completed',
        amount: 1000,
        duration: 12,
        interestRate: 0,
        startDate: DateTime.now().subtract(const Duration(days: 730)),
        endDate: DateTime.now().subtract(const Duration(days: 365)),
        dayOfMonth: 1,
        lenderName: 'Bank',
        accountId: 1,
      );

      when(
        () => mockRepository.getAll(),
      ).thenReturn([activeLoan, completedLoan]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(loanProvider.future);

      final completed = container
          .read(loanProvider.notifier)
          .getCompletedLoans();
      expect(completed.length, 1);
      expect(completed.first.name, 'Completed');
    },
  );

  test('getTotalMonthlyPayments returns 0 during deferred period', () async {
    final deferredLoan = LoanModel(
      name: 'PTZ',
      amount: 50000,
      duration: 120,
      interestRate: 0,
      startDate: DateTime.now().subtract(const Duration(days: 180)),
      endDate: DateTime.now().add(const Duration(days: 3100)),
      dayOfMonth: 1,
      lenderName: 'État',
      accountId: 1,
      deferredMonths: 24,
    );

    when(() => mockRepository.getAll()).thenReturn([deferredLoan]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(loanProvider.future);

    final monthly = container
        .read(loanProvider.notifier)
        .getTotalMonthlyPayments();
    expect(monthly, 0.0);
  });

  test('should set error state when repository fails', () async {
    when(() => mockRepository.getAll()).thenThrow(Exception('DB Error'));

    final container = makeContainer();
    addTearDown(container.dispose);

    final completer = Completer<void>();
    container.listen<AsyncValue<List<Loan>>>(loanProvider, (previous, next) {
      if (next.hasError && !completer.isCompleted) {
        completer.complete();
      }
    }, fireImmediately: true);

    await completer.future;
    expect(container.read(loanProvider).hasError, true);
  });
}
