import 'dart:convert';
import 'dart:io';

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
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybudget/core/services/preferences_service.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBuildContext extends Mock implements BuildContext {}

class MockFile extends Mock implements File {}

class FakeAccountModel extends Fake implements AccountModel {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

class FakeBeneficiaryModel extends Fake implements BeneficiaryModel {}

void main() {
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
    registerFallbackValue(FakeBeneficiaryModel());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    mockAccountRepo = MockAccountRepository();
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockCategoryRepo = MockCategoryRepository();

    mockContext = MockBuildContext();
    mockFile = MockFile();

    when(() => mockContext.mounted).thenReturn(false);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        beneficiaryRepositoryProvider.overrideWithValue(mockBeneficiaryRepo),
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        revenueRepositoryProvider.overrideWithValue(mockRevenueRepo),
        loanRepositoryProvider.overrideWithValue(mockLoanRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
      ],
    );
  }

  test(
    'importUserData should correctly map old account IDs to new ones',
    () async {
      // JSON with an account (id=100) and an expense referencing it (accountId=100).
      // No categories → categoryId is omitted so the expense is not skipped.
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

      when(() => mockFile.readAsString()).thenAnswer((_) async => jsonContent);

      when(() => mockBeneficiaryRepo.deleteAll()).thenReturn(null);
      when(() => mockAccountRepo.deleteAll()).thenReturn(null);
      when(() => mockExpenseRepo.deleteAll()).thenReturn(null);
      when(() => mockRevenueRepo.deleteAll()).thenReturn(null);
      when(() => mockLoanRepo.deleteAll()).thenReturn(null);
      when(() => mockCategoryRepo.deleteAll()).thenReturn(null);

      // accountRepo.add returns new ID 200 (remapped from old ID 100)
      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockExpenseRepo.add(any())).thenReturn(1);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(dataProvider.notifier).importUserData(mockContext, mockFile);

      verify(() => mockAccountRepo.deleteAll()).called(1);
      verify(() => mockAccountRepo.add(any())).called(1);

      final captured = verify(() => mockExpenseRepo.add(captureAny())).captured;
      final addedExpense = captured.first as ExpenseModel;

      // The expense's accountId should be remapped from 100 → 200
      expect(addedExpense.accountId, 200);
    },
  );

  test('importUserData with invalid JSON sets error state', () async {
    when(() => mockFile.readAsString()).thenAnswer((_) async => 'NOT VALID JSON {{{');

    when(() => mockBeneficiaryRepo.deleteAll()).thenReturn(null);
    when(() => mockAccountRepo.deleteAll()).thenReturn(null);
    when(() => mockExpenseRepo.deleteAll()).thenReturn(null);
    when(() => mockRevenueRepo.deleteAll()).thenReturn(null);
    when(() => mockLoanRepo.deleteAll()).thenReturn(null);
    when(() => mockCategoryRepo.deleteAll()).thenReturn(null);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dataProvider.notifier).importUserData(mockContext, mockFile);

    // L'état d'erreur doit être défini, pas de crash
    expect(container.read(dataProvider).error, isNotEmpty);
    expect(container.read(dataProvider).isImporting, isFalse);
  });

  test('importUserData ignores expense with orphan categoryId', () async {
    // Le compte existe (100→200), mais la catégorie (id=99) n'est pas dans le JSON
    // → l'expense doit être ignorée
    final jsonContent = jsonEncode({
      'accounts': [
        {'id': '100', 'name': 'Account', 'bank': 'Bank'},
      ],
      'expenses': [
        {
          'id': '1',
          'name': 'Orphan expense',
          'amount': 50.0,
          'accountId': 100,
          'categoryId': 99, // catégorie introuvable dans le mapping
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

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dataProvider.notifier).importUserData(mockContext, mockFile);

    // L'expense avec categoryId orphelin doit être ignorée
    verifyNever(() => mockExpenseRepo.add(any()));
  });

  test('importUserData correctly remaps beneficiaryId', () async {
    // Un bénéficiaire (id=10) et une dépense le référençant → remapping beneficiaryId
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
          'beneficiaryId': '10', // doit être remappé
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
    when(() => mockBeneficiaryRepo.add(any())).thenReturn(55); // nouveau ID
    when(() => mockAccountRepo.add(any())).thenReturn(200);
    when(() => mockExpenseRepo.add(any())).thenReturn(1);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dataProvider.notifier).importUserData(mockContext, mockFile);

    final captured = verify(() => mockExpenseRepo.add(captureAny())).captured;
    final addedExpense = captured.first as ExpenseModel;

    // beneficiaryId doit être remappé de 10 → 55
    expect(addedExpense.beneficiaryId, 55);
  });
}
