import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/data/data_import_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}


class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class FakeAccountModel extends Fake implements AccountModel {}

class FakeBeneficiaryModel extends Fake implements BeneficiaryModel {}

class FakeCategoryOverrideModel extends Fake
    implements CategoryOverrideModel {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

class FakeRevenueModel extends Fake implements RevenueModel {}

class FakeLoanModel extends Fake implements LoanModel {}

class MockTransferRepository extends Mock implements TransferRepository {}

class FakeTransferModel extends Fake implements TransferModel {}

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
  late DataImportService service;

  setUpAll(() {
    registerFallbackValue(FakeAccountModel());
    registerFallbackValue(FakeBeneficiaryModel());
    registerFallbackValue(FakeCategoryOverrideModel());
    registerFallbackValue(FakeExpenseModel());
    registerFallbackValue(FakeRevenueModel());
    registerFallbackValue(FakeLoanModel());
    registerFallbackValue(FakeTransferModel());
  });

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockTransferRepo = MockTransferRepository();
    mockCategoryOverrideRepo = MockCategoryOverrideRepository();
    mockCategoryMemoryRepo = MockCategoryMemoryRepository();

    service = DataImportService(
      accountRepo: mockAccountRepo,
      beneficiaryRepo: mockBeneficiaryRepo,
      categoryOverrideRepo: mockCategoryOverrideRepo,
      categoryMemoryRepo: mockCategoryMemoryRepo,
      expenseRepo: mockExpenseRepo,
      revenueRepo: mockRevenueRepo,
      loanRepo: mockLoanRepo,
      transferRepo: mockTransferRepo,
    );
  });

  group('validate()', () {
    test('parses valid JSON with all entity types', () {
      final data = _buildFullJsonData();

      final result = service.validate(data);

      expect(result.isValid, isTrue);
      expect(result.beneficiaries, hasLength(1));
      expect(result.accounts, hasLength(1));
      expect(result.categoryOverrides, hasLength(1));
      expect(result.expenses, hasLength(1));
      expect(result.revenues, hasLength(1));
      expect(result.loans, hasLength(1));
      expect(result.transfers, hasLength(1));
      expect(result.errors, isEmpty);
      expect(result.totalItems, 7);
    });

    test('returns empty lists for missing keys', () {
      final result = service.validate({});

      expect(result.isValid, isTrue);
      expect(result.beneficiaries, isEmpty);
      expect(result.accounts, isEmpty);
      expect(result.categoryOverrides, isEmpty);
      expect(result.expenses, isEmpty);
      expect(result.revenues, isEmpty);
      expect(result.loans, isEmpty);
      expect(result.errors, isEmpty);
      expect(result.totalItems, 0);
    });

    test('preserves old IDs in parsed wrappers', () {
      final data = {
        'beneficiaries': [
          {'id': '10', 'name': 'Alice'},
        ],
        'accounts': [
          {'id': '20', 'name': 'Compte', 'bank': 'BNP'},
        ],
        'categoryOverrides': [
          {'slug': 'loisirs.cinema_sortie', 'name': 'Sorties ciné'},
      ],
      };

      final result = service.validate(data);

      expect(result.beneficiaries.first.oldId, 10);
      expect(result.beneficiaries.first.model.id, 0);
      expect(result.accounts.first.oldId, 20);
      expect(result.accounts.first.model.id, 0);
      expect(result.categoryOverrides.first.model.id, 0);
    });

    test('preserves old foreign keys in expenses', () {
      final data = {
        'expenses': [
          {
            'id': '1',
            'name': 'Loyer',
            'amount': 800.0,
            'accountId': 20,
            'categorySlug': 'logement.loyer',
            'beneficiaryId': '10',
            'startDate': '2025-01-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final result = service.validate(data);

      final expense = result.expenses.first;
      expect(expense.oldAccountId, 20);
      expect(expense.model.categorySlug, 'logement.loyer');
      expect(expense.oldBeneficiaryId, 10);
      expect(expense.model.id, 0);
    });

    test('preserves old foreign keys in revenues', () {
      final data = {
        'revenues': [
          {
            'id': '1',
            'name': 'Salaire',
            'amount': 3000.0,
            'accountId': 20,
            'beneficiaryId': '10',

            'startDate': '2025-01-01T00:00:00.000',
          },
        ],
      };

      final result = service.validate(data);

      final revenue = result.revenues.first;
      expect(revenue.oldAccountId, 20);
      expect(revenue.oldBeneficiaryId, 10);
    });

    test('preserves old account IDs in transfers', () {
      final data = {
        'transfers': [
          {
            'id': '1',
            'name': 'Epargne',
            'amount': 500.0,
            'fromAccountId': 20,
            'toAccountId': 30,
            'startDate': '2025-03-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final result = service.validate(data);

      expect(result.transfers, hasLength(1));
      expect(result.transfers.first.oldFromAccountId, 20);
      expect(result.transfers.first.oldToAccountId, 30);
      expect(result.transfers.first.model.id, 0);
    });

    test('preserves old accountId in loans (camelCase)', () {
      final data = {
        'loans': [
          _buildLoanJson(accountId: '50'),
        ],
      };

      final result = service.validate(data);

      expect(result.loans.first.oldAccountId, 50);
      expect(result.loans.first.model.id, 0);
    });

    test('preserves old accountId in loans (snake_case legacy)', () {
      final json = _buildLoanJson();
      json.remove('accountId');
      json['account_id'] = '75';

      final data = {'loans': [json]};

      final result = service.validate(data);

      expect(result.loans.first.oldAccountId, 75);
    });

    test('collects errors for malformed items without stopping', () {
      final data = {
        'beneficiaries': [
          {'id': '1', 'name': 'OK'},
          'not a map',
        ],
        'accounts': [
          {'id': '1', 'name': 'OK', 'bank': 'BNP'},
          42,
        ],
      };

      final result = service.validate(data);

      expect(result.isValid, isTrue);
      expect(result.beneficiaries, hasLength(1));
      expect(result.accounts, hasLength(1));
      expect(result.errors, hasLength(2));
    });

    test('hasCategoryOverrides returns true when categories present', () {
      final data = {
        'categoryOverrides': [
          {'slug': 'loisirs.cinema_sortie', 'name': 'Sorties ciné'},
      ],
      };

      final result = service.validate(data);

      expect(result.hasCategoryOverrides, isTrue);
    });

    test('hasCategoryOverrides returns false when no categories', () {
      final result = service.validate({});

      expect(result.hasCategoryOverrides, isFalse);
    });
  });

  group('category memory', () {
    test('validate() parses remembered categories', () {
      final result = service.validate({
        'categoryMemory': [
          {
            'key': 'macdo',
            'slug': 'restauration.fast_food',
            'corrections': 3,
            'useMemory': true,
            'updatedAt': '2026-08-21T00:00:00.000',
          },
        ],
      });

      expect(result.categoryMemory, hasLength(1));
      final entry = result.categoryMemory.first.model;
      expect(entry.key, 'macdo');
      expect(entry.slug, 'restauration.fast_food');
      expect(entry.corrections, 3);
      expect(entry.useMemory, isTrue);
    });

    test('validate() defaults a partial entry', () {
      final result = service.validate({
        'categoryMemory': [
          {'key': 'macdo', 'slug': 'restauration.fast_food'},
        ],
      });

      final entry = result.categoryMemory.first.model;
      expect(entry.corrections, 1);
      expect(entry.useMemory, isTrue);
    });
  });

  group('execute()', () {
    void stubDeleteAll() {
      when(() => mockBeneficiaryRepo.deleteAll()).thenReturn(null);
      when(() => mockAccountRepo.deleteAll()).thenReturn(null);
      when(() => mockCategoryOverrideRepo.deleteAll()).thenReturn(null);
    when(() => mockCategoryMemoryRepo.deleteAll()).thenReturn(null);
      when(() => mockCategoryMemoryRepo.deleteAll()).thenReturn(null);
      when(() => mockExpenseRepo.deleteAll()).thenReturn(null);
      when(() => mockRevenueRepo.deleteAll()).thenReturn(null);
      when(() => mockLoanRepo.deleteAll()).thenReturn(null);
      when(() => mockTransferRepo.deleteAll()).thenReturn(null);
    }

    test('deletes all existing data before inserting', () {
      stubDeleteAll();

      final validated = service.validate({});
      service.execute(validated);

      verify(() => mockCategoryMemoryRepo.deleteAll()).called(1);

      verify(() => mockBeneficiaryRepo.deleteAll()).called(1);
      verify(() => mockAccountRepo.deleteAll()).called(1);
      verify(() => mockCategoryOverrideRepo.deleteAll()).called(1);
      verify(() => mockExpenseRepo.deleteAll()).called(1);
      verify(() => mockRevenueRepo.deleteAll()).called(1);
      verify(() => mockLoanRepo.deleteAll()).called(1);
    });

    test('remaps accountId in expenses', () {
      stubDeleteAll();
      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockExpenseRepo.add(any())).thenReturn(1);

      final data = {
        'accounts': [
          {'id': '100', 'name': 'Compte', 'bank': 'BNP'},
        ],
        'expenses': [
          {
            'id': '1',
            'name': 'Loyer',
            'amount': 800.0,
            'accountId': 100,
            'startDate': '2025-01-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final validated = service.validate(data);
      service.execute(validated);

      final captured =
          verify(() => mockExpenseRepo.add(captureAny())).captured;
      final expense = captured.first as ExpenseModel;
      expect(expense.accountId, 200);
    });

    test('remaps beneficiaryId in expenses', () {
      stubDeleteAll();
      when(() => mockBeneficiaryRepo.add(any())).thenReturn(55);
      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockExpenseRepo.add(any())).thenReturn(1);

      final data = {
        'beneficiaries': [
          {'id': '10', 'name': 'Alice'},
        ],
        'accounts': [
          {'id': '100', 'name': 'Compte', 'bank': 'BNP'},
        ],
        'expenses': [
          {
            'id': '1',
            'name': 'Expense',
            'amount': 50.0,
            'accountId': 100,
            'beneficiaryId': '10',
            'startDate': '2025-01-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final validated = service.validate(data);
      service.execute(validated);

      final captured =
          verify(() => mockExpenseRepo.add(captureAny())).captured;
      final expense = captured.first as ExpenseModel;
      expect(expense.beneficiaryId, 55);
    });

    test('skips expenses with orphan accountId', () {
      stubDeleteAll();

      final data = {
        'expenses': [
          {
            'id': '1',
            'name': 'Orphan',
            'amount': 50.0,
            'accountId': 999,
            'startDate': '2025-01-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final validated = service.validate(data);
      final report = service.execute(validated);

      verifyNever(() => mockExpenseRepo.add(any()));
      expect(report.expenses.skipped, 1);
      expect(report.expenses.imported, 0);
    });

    test('remaps accountId in revenues', () {
      stubDeleteAll();
      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockRevenueRepo.add(any())).thenReturn(1);

      final data = {
        'accounts': [
          {'id': '100', 'name': 'Compte', 'bank': 'BNP'},
        ],
        'revenues': [
          {
            'id': '1',
            'name': 'Salaire',
            'amount': 3000.0,
            'accountId': 100,

            'startDate': '2025-01-01T00:00:00.000',
          },
        ],
      };

      final validated = service.validate(data);
      service.execute(validated);

      final captured =
          verify(() => mockRevenueRepo.add(captureAny())).captured;
      final revenue = captured.first as RevenueModel;
      expect(revenue.accountId, 200);
    });

    test('remaps accountId in loans', () {
      stubDeleteAll();
      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockLoanRepo.add(any())).thenReturn(1);

      final data = {
        'accounts': [
          {'id': '100', 'name': 'Compte', 'bank': 'BNP'},
        ],
        'loans': [
          _buildLoanJson(accountId: '100'),
        ],
      };

      final validated = service.validate(data);
      service.execute(validated);

      final captured = verify(() => mockLoanRepo.add(captureAny())).captured;
      final loan = captured.first as LoanModel;
      expect(loan.accountId, 200);
    });

    test('remaps both account IDs in transfers', () {
      stubDeleteAll();
      when(() => mockAccountRepo.add(any())).thenAnswer((invocation) {
        final model = invocation.positionalArguments[0] as AccountModel;
        return model.name == 'Compte A' ? 200 : 300;
      });
      when(() => mockTransferRepo.add(any())).thenReturn(1);

      final data = {
        'accounts': [
          {'id': '10', 'name': 'Compte A', 'bank': 'BNP'},
          {'id': '20', 'name': 'Compte B', 'bank': 'SG'},
        ],
        'transfers': [
          {
            'id': '1',
            'name': 'Epargne',
            'amount': 500.0,
            'fromAccountId': 10,
            'toAccountId': 20,
            'startDate': '2025-03-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final validated = service.validate(data);
      service.execute(validated);

      final captured = verify(() => mockTransferRepo.add(captureAny())).captured;
      final transfer = captured.first as TransferModel;
      expect(transfer.fromAccountId, 200);
      expect(transfer.toAccountId, 300);
    });

    test('skips transfers with orphan account IDs', () {
      stubDeleteAll();

      final data = {
        'transfers': [
          {
            'id': '1',
            'name': 'Orphan',
            'amount': 100.0,
            'fromAccountId': 999,
            'toAccountId': 888,
            'startDate': '2025-03-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final validated = service.validate(data);
      final report = service.execute(validated);

      verifyNever(() => mockTransferRepo.add(any()));
      expect(report.transfers.skipped, 1);
      expect(report.transfers.imported, 0);
    });

    test('skips loans with orphan accountId', () {
      stubDeleteAll();

      final data = {
        'loans': [
          _buildLoanJson(accountId: '999'),
        ],
      };

      final validated = service.validate(data);
      final report = service.execute(validated);

      verifyNever(() => mockLoanRepo.add(any()));
      expect(report.loans.skipped, 1);
    });

    test('returns correct ImportReport counters', () {
      stubDeleteAll();
      when(() => mockBeneficiaryRepo.add(any())).thenReturn(1);
      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockCategoryOverrideRepo.save(any())).thenReturn(null);
      when(() => mockExpenseRepo.add(any())).thenReturn(1);
      when(() => mockRevenueRepo.add(any())).thenReturn(1);
      when(() => mockLoanRepo.add(any())).thenReturn(1);
      when(() => mockTransferRepo.add(any())).thenReturn(1);

      final data = _buildFullJsonData();
      final validated = service.validate(data);
      final report = service.execute(validated);

      expect(report.beneficiaries.total, 1);
      expect(report.beneficiaries.imported, 1);
      expect(report.accounts.total, 1);
      expect(report.accounts.imported, 1);
      expect(report.categories.total, 1);
      expect(report.categories.imported, 1);
      expect(report.expenses.total, 1);
      expect(report.expenses.imported, 1);
      expect(report.revenues.total, 1);
      expect(report.revenues.imported, 1);
      expect(report.loans.total, 1);
      expect(report.loans.imported, 1);
      expect(report.transfers.total, 1);
      expect(report.transfers.imported, 1);
      expect(report.totalImported, 7);
      expect(report.hasWarnings, isFalse);
    });

    test('onProgress callback is called with correct values', () {
      stubDeleteAll();
      when(() => mockBeneficiaryRepo.add(any())).thenReturn(1);
      when(() => mockAccountRepo.add(any())).thenReturn(200);

      final data = {
        'beneficiaries': [
          {'id': '1', 'name': 'Alice'},
        ],
        'accounts': [
          {'id': '100', 'name': 'Compte', 'bank': 'BNP'},
        ],
      };

      final progressValues = <double>[];
      final statusValues = <String>[];

      final validated = service.validate(data);
      service.execute(
        validated,
        onProgress: (progress, status) {
          progressValues.add(progress);
          statusValues.add(status);
        },
      );

      expect(progressValues.first, 0.0);
      expect(progressValues.last, 1.0);
      for (final p in progressValues) {
        expect(p, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}

Map<String, dynamic> _buildFullJsonData() {
  return {
    'beneficiaries': [
      {'id': '10', 'name': 'Alice'},
    ],
    'accounts': [
      {'id': '100', 'name': 'Compte Courant', 'bank': 'BNP'},
    ],
    'categoryOverrides': [
      {'slug': 'loisirs.cinema_sortie', 'name': 'Sorties ciné'},
      ],
    'expenses': [
      {
        'id': '1',
        'name': 'Netflix',
        'amount': 15.0,
        'accountId': 100,
        'categoryId': 50,
        'beneficiaryId': '10',
        'startDate': '2025-01-15T00:00:00.000',
        'frequency': 'Mensuel',
      },
    ],
    'revenues': [
      {
        'id': '1',
        'name': 'Salaire',
        'amount': 3000.0,
        'accountId': 100,
        'beneficiaryId': '10',
        'startDate': '2025-01-01T00:00:00.000',
      },
    ],
    'loans': [
      _buildLoanJson(accountId: '100'),
    ],
    'transfers': [
      {
        'id': '1',
        'name': 'Epargne',
        'amount': 500.0,
        'fromAccountId': 100,
        'toAccountId': 100,
        'startDate': '2025-03-15T00:00:00.000',
        'frequency': 'Mensuel',
      },
    ],
  };
}

Map<String, dynamic> _buildLoanJson({String accountId = '100'}) {
  return {
    'id': '1',
    'name': 'Prêt immobilier',
    'amount': 200000.0,
    'accountId': accountId,
    'lenderName': 'BNP Paribas',
    'dayOfMonth': 5,
    'startDate': '2024-01-01T00:00:00.000',
    'endDate': '2044-01-01T00:00:00.000',
    'interestRate': 3.5,
    'duration': 240,
    'repaymentTypeId': 'amortizable',
    'deferredMonths': 0,
    'insuranceTypeId': 'none',
    'insuranceValue': 0.0,
    'insuranceCalculationModeId': 'initialCapital',
  };
}
