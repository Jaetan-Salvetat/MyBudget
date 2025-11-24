import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/models/loan_model.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late LoanViewModel viewModel;
  late MockLoanRepository mockLoanRepository;

  setUp(() {
    mockLoanRepository = MockLoanRepository();

    when(() => mockLoanRepository.getAll()).thenReturn([]);

    viewModel = LoanViewModel(mockLoanRepository);
  });

  group('LoanViewModel', () {
    test('initial load should fetch loans', () async {
      verify(() => mockLoanRepository.getAll()).called(1);
      expect(viewModel.loans, isEmpty);
      expect(viewModel.isLoading, false);
    });

    test('addLoan should call repository and reload', () async {
      final loan = LoanModel.create(
        name: 'New Loan',
        amount: 1000.0,
        lenderName: 'Bank',
        dayOfMonth: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        accountId: 1,
        monthlyPayment: 100.0,
      );

      when(() => mockLoanRepository.add(loan)).thenReturn(1);
      when(() => mockLoanRepository.getAll()).thenReturn([loan]);

      await viewModel.addLoan(loan);

      verify(() => mockLoanRepository.add(loan)).called(1);
      verify(() => mockLoanRepository.getAll()).called(2);
      expect(viewModel.loans.length, 1);
    });

    test('deleteLoan should call repository and reload', () async {
      when(() => mockLoanRepository.delete(1)).thenReturn(true);

      await viewModel.deleteLoan(1);

      verify(() => mockLoanRepository.delete(1)).called(1);
      verify(() => mockLoanRepository.getAll()).called(2);
    });

    test('getTotalRemainingAmount should calculate correctly', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final loan = LoanModel.create(
        name: 'Future Loan',
        amount: 1000.0,
        lenderName: 'Bank',
        dayOfMonth: 1,
        startDate: futureDate,
        endDate: futureDate.add(const Duration(days: 365)),
        accountId: 1,
        monthlyPayment: 100.0,
      );

      when(() => mockLoanRepository.getAll()).thenReturn([loan]);
      viewModel = LoanViewModel(mockLoanRepository);

      expect(viewModel.getTotalRemainingAmount(), 1000.0);
    });
  });
}
