import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/data/data_import_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class FakeAccountModel extends Fake implements AccountModel {}

class FakeBeneficiaryModel extends Fake implements BeneficiaryModel {}

class FakeCategoryModel extends Fake implements CategoryModel {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

class FakeRevenueModel extends Fake implements RevenueModel {}

class FakeLoanModel extends Fake implements LoanModel {}

void main() {
  late MockAccountRepository mockAccountRepo;
  late MockBeneficiaryRepository mockBeneficiaryRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late DataImportService service;

  setUpAll(() {
    registerFallbackValue(FakeAccountModel());
    registerFallbackValue(FakeBeneficiaryModel());
    registerFallbackValue(FakeCategoryModel());
    registerFallbackValue(FakeExpenseModel());
    registerFallbackValue(FakeRevenueModel());
    registerFallbackValue(FakeLoanModel());
  });

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();

    service = DataImportService(
      accountRepo: mockAccountRepo,
      beneficiaryRepo: mockBeneficiaryRepo,
      categoryRepo: mockCategoryRepo,
      expenseRepo: mockExpenseRepo,
      revenueRepo: mockRevenueRepo,
      loanRepo: mockLoanRepo,
    );
  });

  group('validate()', () {
    test('parses valid JSON with all entity types', () {
      final data = _buildFullJsonData();

      final result = service.validate(data);

      expect(result.isValid, isTrue);
      expect(result.beneficiaries, hasLength(1));
      expect(result.accounts, hasLength(1));
      expect(result.categories, hasLength(1));
      expect(result.expenses, hasLength(1));
      expect(result.revenues, hasLength(1));
      expect(result.loans, hasLength(1));
      expect(result.errors, isEmpty);
      expect(result.totalItems, 6);
    });

    test('returns empty lists for missing keys', () {
      final result = service.validate({});

      expect(result.isValid, isTrue);
      expect(result.beneficiaries, isEmpty);
      expect(result.accounts, isEmpty);
      expect(result.categories, isEmpty);
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
        'categories': [
          {'id': '30', 'name': 'Loisirs', 'icon': 'movie', 'color': 0xFF00FF00},
        ],
      };

      final result = service.validate(data);

      expect(result.beneficiaries.first.oldId, 10);
      expect(result.beneficiaries.first.model.id, 0);
      expect(result.accounts.first.oldId, 20);
      expect(result.accounts.first.model.id, 0);
      expect(result.categories.first.oldId, 30);
      expect(result.categories.first.model.id, 0);
    });

    test('preserves old foreign keys in expenses', () {
      final data = {
        'expenses': [
          {
            'id': '1',
            'name': 'Loyer',
            'amount': 800.0,
            'accountId': 20,
            'categoryId': 30,
            'beneficiaryId': '10',
            'date': '2025-01-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final result = service.validate(data);

      final expense = result.expenses.first;
      expect(expense.oldAccountId, 20);
      expect(expense.oldCategoryId, 30);
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

            'date': '2025-01-01T00:00:00.000',
          },
        ],
      };

      final result = service.validate(data);

      final revenue = result.revenues.first;
      expect(revenue.oldAccountId, 20);
      expect(revenue.oldBeneficiaryId, 10);
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

    test('hasCategories returns true when categories present', () {
      final data = {
        'categories': [
          {'id': '1', 'name': 'Transport', 'icon': 'directions_car'},
        ],
      };

      final result = service.validate(data);

      expect(result.hasCategories, isTrue);
    });

    test('hasCategories returns false when no categories', () {
      final result = service.validate({});

      expect(result.hasCategories, isFalse);
    });
  });

  group('execute()', () {
    void stubDeleteAll() {
      when(() => mockBeneficiaryRepo.deleteAll()).thenReturn(null);
      when(() => mockAccountRepo.deleteAll()).thenReturn(null);
      when(() => mockCategoryRepo.deleteAll()).thenReturn(null);
      when(() => mockExpenseRepo.deleteAll()).thenReturn(null);
      when(() => mockRevenueRepo.deleteAll()).thenReturn(null);
      when(() => mockLoanRepo.deleteAll()).thenReturn(null);
    }

    test('deletes all existing data before inserting', () {
      stubDeleteAll();

      final validated = service.validate({});
      service.execute(validated);

      verify(() => mockBeneficiaryRepo.deleteAll()).called(1);
      verify(() => mockAccountRepo.deleteAll()).called(1);
      verify(() => mockCategoryRepo.deleteAll()).called(1);
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
            'date': '2025-01-15T00:00:00.000',
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

    test('remaps categoryId in expenses', () {
      stubDeleteAll();
      when(() => mockAccountRepo.add(any())).thenReturn(200);
      when(() => mockCategoryRepo.add(any())).thenReturn(300);
      when(() => mockExpenseRepo.add(any())).thenReturn(1);

      final data = {
        'accounts': [
          {'id': '100', 'name': 'Compte', 'bank': 'BNP'},
        ],
        'categories': [
          {'id': '50', 'name': 'Loisirs', 'icon': 'movie'},
        ],
        'expenses': [
          {
            'id': '1',
            'name': 'Netflix',
            'amount': 15.0,
            'accountId': 100,
            'categoryId': 50,
            'date': '2025-01-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final validated = service.validate(data);
      service.execute(validated);

      final captured =
          verify(() => mockExpenseRepo.add(captureAny())).captured;
      final expense = captured.first as ExpenseModel;
      expect(expense.categoryId, 300);
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
            'date': '2025-01-15T00:00:00.000',
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
            'date': '2025-01-15T00:00:00.000',
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

    test('skips expenses with orphan categoryId', () {
      stubDeleteAll();
      when(() => mockAccountRepo.add(any())).thenReturn(200);

      final data = {
        'accounts': [
          {'id': '100', 'name': 'Compte', 'bank': 'BNP'},
        ],
        'expenses': [
          {
            'id': '1',
            'name': 'Orphan cat',
            'amount': 50.0,
            'accountId': 100,
            'categoryId': 999,
            'date': '2025-01-15T00:00:00.000',
            'frequency': 'Mensuel',
          },
        ],
      };

      final validated = service.validate(data);
      final report = service.execute(validated);

      verifyNever(() => mockExpenseRepo.add(any()));
      expect(report.expenses.skipped, 1);
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

            'date': '2025-01-01T00:00:00.000',
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
      when(() => mockCategoryRepo.add(any())).thenReturn(300);
      when(() => mockExpenseRepo.add(any())).thenReturn(1);
      when(() => mockRevenueRepo.add(any())).thenReturn(1);
      when(() => mockLoanRepo.add(any())).thenReturn(1);

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
      expect(report.totalImported, 6);
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
    'categories': [
      {'id': '50', 'name': 'Loisirs', 'icon': 'movie', 'color': 0xFF2196F3},
    ],
    'expenses': [
      {
        'id': '1',
        'name': 'Netflix',
        'amount': 15.0,
        'accountId': 100,
        'categoryId': 50,
        'beneficiaryId': '10',
        'date': '2025-01-15T00:00:00.000',
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
        'date': '2025-01-01T00:00:00.000',
      },
    ],
    'loans': [
      _buildLoanJson(accountId: '100'),
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
