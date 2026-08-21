import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/settings/data_provider.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybudget/core/services/preferences_service.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}


class MockTransferRepository extends Mock implements TransferRepository {}

class FakeAccountModel extends Fake implements AccountModel {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

class FakeBeneficiaryModel extends Fake implements BeneficiaryModel {}

class FakeCategoryOverrideModel extends Fake
    implements CategoryOverrideModel {}

class FakeRevenueModel extends Fake implements RevenueModel {}

class FakeLoanModel extends Fake implements LoanModel {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockCategoryMemoryRepository extends Mock
    implements CategoryMemoryRepository {}

void main() {
  late MockAccountRepository mockAccountRepo;
  late MockBeneficiaryRepository mockBeneficiaryRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late MockTransferRepository mockTransferRepo;
  late MockCategoryOverrideRepository mockCategoryOverrideRepo;
  late MockCategoryMemoryRepository mockCategoryMemoryRepo;

  setUpAll(() {
    registerFallbackValue(FakeAccountModel());
    registerFallbackValue(FakeExpenseModel());
    registerFallbackValue(FakeBeneficiaryModel());
    registerFallbackValue(FakeCategoryOverrideModel());
    registerFallbackValue(FakeRevenueModel());
    registerFallbackValue(FakeLoanModel());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    mockAccountRepo = MockAccountRepository();
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockTransferRepo = MockTransferRepository();
    mockCategoryOverrideRepo = MockCategoryOverrideRepository();
    mockCategoryMemoryRepo = MockCategoryMemoryRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        beneficiaryRepositoryProvider.overrideWithValue(mockBeneficiaryRepo),
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        revenueRepositoryProvider.overrideWithValue(mockRevenueRepo),
        loanRepositoryProvider.overrideWithValue(mockLoanRepo),
        transferRepositoryProvider.overrideWithValue(mockTransferRepo),
        categoryOverrideRepositoryProvider
            .overrideWithValue(mockCategoryOverrideRepo),
        categoryMemoryRepositoryProvider
            .overrideWithValue(mockCategoryMemoryRepo),
      ],
    );
  }

  void stubDeleteAll() {
    when(() => mockBeneficiaryRepo.deleteAll()).thenReturn(null);
    when(() => mockAccountRepo.deleteAll()).thenReturn(null);
    when(() => mockExpenseRepo.deleteAll()).thenReturn(null);
    when(() => mockRevenueRepo.deleteAll()).thenReturn(null);
    when(() => mockLoanRepo.deleteAll()).thenReturn(null);
    when(() => mockCategoryOverrideRepo.deleteAll()).thenReturn(null);
    when(() => mockCategoryMemoryRepo.deleteAll()).thenReturn(null);
    when(() => mockTransferRepo.deleteAll()).thenReturn(null);
  }

  test(
    'importUserData should correctly map old account IDs to new ones',
    () async {
      final jsonContent = jsonEncode({
        'accounts': [
          {'id': '100', 'name': 'Old Account', 'bank': 'Bank A'},
        ],
        'expenses': [
          {
            'id': '500',
            'name': 'Expense on Old Account',
            'amount': 50.0,
            'accountId': 100,
            'date': DateTime.now().toIso8601String(),
            'frequency': 'Mensuel',
          },
        ],
        'revenues': [],
        'loans': [],
      });

      stubDeleteAll();
      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockExpenseRepo.add(any())).thenReturn(1);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(dataProvider.notifier).importUserData(jsonContent);

      verify(() => mockAccountRepo.deleteAll()).called(1);
      verify(() => mockAccountRepo.add(any())).called(1);

      final captured = verify(() => mockExpenseRepo.add(captureAny())).captured;
      final addedExpense = captured.first as ExpenseModel;

      expect(addedExpense.accountId, 200);
    },
  );

  test('importUserData with invalid JSON sets error state', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container
        .read(dataProvider.notifier)
        .importUserData('NOT VALID JSON {{{');

    expect(container.read(dataProvider).error, isNotEmpty);
    expect(container.read(dataProvider).isImporting, isFalse);
  });

  test('importUserData correctly remaps beneficiaryId', () async {
    final jsonContent = jsonEncode({
      'beneficiaries': [
        {'id': '10', 'name': 'Alice'},
      ],
      'accounts': [
        {'id': '100', 'name': 'Account', 'bank': 'Bank'},
      ],
      'expenses': [
        {
          'id': '1',
          'name': 'Expense with beneficiary',
          'amount': 50.0,
          'accountId': 100,
          'beneficiaryId': '10',
          'date': DateTime.now().toIso8601String(),
          'frequency': 'Mensuel',
        },
      ],
      'revenues': [],
      'loans': [],
    });

    stubDeleteAll();
    when(() => mockBeneficiaryRepo.add(any())).thenReturn(55);
    when(() => mockAccountRepo.add(any())).thenReturn(200);
    when(() => mockExpenseRepo.add(any())).thenReturn(1);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dataProvider.notifier).importUserData(jsonContent);

    final captured = verify(() => mockExpenseRepo.add(captureAny())).captured;
    final addedExpense = captured.first as ExpenseModel;

    expect(addedExpense.beneficiaryId, 55);
  });

  test('importUserData sets importReport on success', () async {
    final jsonContent = jsonEncode({
      'accounts': [
        {'id': '100', 'name': 'Account', 'bank': 'Bank'},
      ],
    });

    stubDeleteAll();
    when(() => mockAccountRepo.add(any())).thenReturn(200);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dataProvider.notifier).importUserData(jsonContent);

    final state = container.read(dataProvider);
    expect(state.importReport, isNotNull);
    expect(state.importReport!.accounts.imported, 1);
    expect(state.isImporting, isFalse);
    expect(state.error, isEmpty);
  });

  test('deleteAllUserData deletes all repositories', () async {
    stubDeleteAll();

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dataProvider.notifier).deleteAllUserData();

    verify(() => mockBeneficiaryRepo.deleteAll()).called(1);
    verify(() => mockAccountRepo.deleteAll()).called(1);
    verify(() => mockExpenseRepo.deleteAll()).called(1);
    verify(() => mockRevenueRepo.deleteAll()).called(1);
    verify(() => mockLoanRepo.deleteAll()).called(1);
    verify(() => mockCategoryOverrideRepo.deleteAll()).called(1);

    expect(container.read(dataProvider).isDeleting, isFalse);
  });
}
