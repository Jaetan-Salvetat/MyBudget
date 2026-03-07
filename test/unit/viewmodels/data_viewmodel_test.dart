import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mybudget/ui/settings/data_viewmodel.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAccountViewModel extends Mock implements AccountViewModel {}

class MockExpenseViewModel extends Mock implements ExpenseViewModel {}

class MockRevenueViewModel extends Mock implements RevenueViewModel {}

class MockLoanViewModel extends Mock implements LoanViewModel {}

class MockBuildContext extends Mock implements BuildContext {}

class MockFile extends Mock implements File {}

class FakeAccountModel extends Fake implements AccountModel {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

void main() {
  late DataViewModel viewModel;
  late MockAccountRepository mockAccountRepo;
  late MockBeneficiaryRepository mockBeneficiaryRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockBuildContext mockContext;
  late MockFile mockFile;

  setUpAll(() {
    registerFallbackValue(FakeAccountModel());
    registerFallbackValue(FakeExpenseModel());
  });

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockCategoryRepo = MockCategoryRepository();

    final mockAccountVM = MockAccountViewModel();
    final mockExpenseVM = MockExpenseViewModel();
    final mockRevenueVM = MockRevenueViewModel();
    final mockLoanVM = MockLoanViewModel();

    mockContext = MockBuildContext();
    mockFile = MockFile();

    when(() => mockContext.mounted).thenReturn(false);

    viewModel = DataViewModel(
      mockAccountRepo,
      mockBeneficiaryRepo,
      mockExpenseRepo,
      mockRevenueRepo,
      mockLoanRepo,
      mockCategoryRepo,
      mockAccountVM,
      mockExpenseVM,
      mockRevenueVM,
      mockLoanVM,
    );
  });

  test(
    'importUserData should correctly map old account IDs to new ones',
    () async {
      final jsonContent = jsonEncode({
        'accounts': [
          {'id': 100, 'name': 'Old Account', 'bank': 'Bank A'},
        ],
        'expenses': [
          {
            'id': 500,
            'name': 'Expense on Old Account',
            'amount': 50.0,
            'accountId': 100,
            'categoryId': 1,
            'date': DateTime.now().toIso8601String(),
            'frequency': 'Mensuel',
          },
        ],
        'revenues': [],
        'loans': [],
      });

      when(() => mockFile.readAsString()).thenAnswer((_) async => jsonContent);

      when(() => mockBeneficiaryRepo.deleteAll()).thenReturn(null);
      when(() => mockAccountRepo.deleteAll()).thenReturn(null);
      when(() => mockExpenseRepo.deleteAll()).thenReturn(null);
      when(() => mockRevenueRepo.deleteAll()).thenReturn(null);
      when(() => mockLoanRepo.deleteAll()).thenReturn(null);
      when(() => mockCategoryRepo.deleteAll()).thenReturn(null);

      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockExpenseRepo.add(any())).thenReturn(1);

      await viewModel.importUserData(mockContext, mockFile);

      verify(() => mockAccountRepo.deleteAll()).called(1);

      verify(() => mockAccountRepo.add(any())).called(1);

      final captured = verify(() => mockExpenseRepo.add(captureAny())).captured;
      final addedExpense = captured.first as ExpenseModel;

      expect(addedExpense.accountId, 200);
    },
  );
}
