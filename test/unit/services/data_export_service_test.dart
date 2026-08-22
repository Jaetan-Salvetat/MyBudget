import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/models/category_memory_model.dart';
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
import 'package:mybudget/core/services/data/data_export_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/transfer_model.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockTransferRepository extends Mock implements TransferRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockCategoryMemoryRepository extends Mock
    implements CategoryMemoryRepository {}

void main() {
  late DataExportService service;
  late MockAccountRepository mockAccountRepo;
  late MockBeneficiaryRepository mockBeneficiaryRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late MockTransferRepository mockTransferRepo;
  late MockCategoryOverrideRepository mockCategoryOverrideRepo;
  late MockCategoryMemoryRepository mockCategoryMemoryRepo;

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockTransferRepo = MockTransferRepository();
    mockCategoryOverrideRepo = MockCategoryOverrideRepository();
    mockCategoryMemoryRepo = MockCategoryMemoryRepository();

    service = DataExportService(
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

  void stubEmptyRepos() {
    when(() => mockAccountRepo.getAll()).thenReturn([]);
    when(() => mockBeneficiaryRepo.getAll()).thenReturn([]);
    when(() => mockCategoryOverrideRepo.getAll()).thenReturn({});
    when(() => mockCategoryMemoryRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
    when(() => mockTransferRepo.getAll()).thenReturn([]);
  }

  test('buildExportData returns correct structure with metadata', () {
    stubEmptyRepos();

    final result = service.buildExportData();

    expect(result['version'], 2);
    expect(result['exportDate'], isNotNull);
    expect(result['filename'], startsWith('mybudget_backup_'));
    expect(result['filename'], endsWith('.json'));
    expect(result['accounts'], isA<List>());
    expect(result['beneficiaries'], isA<List>());
    expect(result['categoryOverrides'], isA<List>());
    expect(result['categoryMemory'], isA<List>());
    expect(result['expenses'], isA<List>());
    expect(result['revenues'], isA<List>());
    expect(result['loans'], isA<List>());
  });

  test('buildExportData serializes all entities via toJson()', () {
    final account = AccountModel.create(name: 'Compte', bank: 'BNP');
    account.id = 1;
    final beneficiary = BeneficiaryModel.create(name: 'Alice');
    beneficiary.id = 2;
    final override = CategoryOverrideModel.create(
      slug: 'loisirs.cinema_sortie',
      name: 'Sorties ciné',
    );
    final expense = ExpenseModel.create(
      name: 'Netflix',
      amount: 15.0,
      categorySlug: 'restauration.cafe',
      accountId: 1,
      startDate: DateTime(2025, 1, 15),
      frequency: 'Mensuel',
    );
    expense.id = 4;
    final revenue = RevenueModel.create(
      name: 'Salaire',
      amount: 3000.0,
      accountId: 1,
      startDate: DateTime(2025, 1, 1),
      frequency: 'Mensuel',
    );
    revenue.id = 5;
    final loan = LoanModel(
      id: 6,
      name: 'Prêt',
      amount: 100000,
      lenderName: 'BNP',
      accountId: 1,
      dayOfMonth: 5,
      startDate: DateTime(2024),
      endDate: DateTime(2044),
      interestRate: 3.0,
      duration: 240,
    );

    when(() => mockAccountRepo.getAll()).thenReturn([account]);
    when(() => mockBeneficiaryRepo.getAll()).thenReturn([beneficiary]);
    when(
      () => mockCategoryOverrideRepo.getAll(),
    ).thenReturn({override.slug: override});
    when(() => mockCategoryMemoryRepo.getAll()).thenReturn([
      CategoryMemoryModel.create(
        key: 'macdo',
        slug: 'restauration.fast_food',
        updatedAt: DateTime(2026, 8, 21),
      ),
    ]);
    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
    when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
    when(() => mockLoanRepo.getAll()).thenReturn([loan]);
    when(() => mockTransferRepo.getAll()).thenReturn([]);

    final result = service.buildExportData();

    expect((result['accounts'] as List), hasLength(1));
    expect((result['accounts'] as List).first['name'], 'Compte');
    expect((result['beneficiaries'] as List).first['name'], 'Alice');
    expect(
      (result['categoryOverrides'] as List).first['slug'],
      'loisirs.cinema_sortie',
    );
    expect((result['categoryMemory'] as List).first['key'], 'macdo');
    expect((result['expenses'] as List).first['name'], 'Netflix');
    expect((result['revenues'] as List).first['name'], 'Salaire');
    expect((result['loans'] as List).first['name'], 'Prêt');
  });

  test('buildExportData uses camelCase keys for loans', () {
    stubEmptyRepos();
    final loan = LoanModel(
      name: 'Prêt',
      amount: 100000,
      lenderName: 'BNP',
      accountId: 1,
      dayOfMonth: 5,
      startDate: DateTime(2024),
      endDate: DateTime(2044),
      interestRate: 3.0,
      duration: 240,
    );
    when(() => mockLoanRepo.getAll()).thenReturn([loan]);

    final result = service.buildExportData();
    final loanJson = (result['loans'] as List).first as Map<String, dynamic>;

    expect(loanJson.containsKey('accountId'), isTrue);
    expect(loanJson.containsKey('lenderName'), isTrue);
    expect(loanJson.containsKey('startDate'), isTrue);
    expect(loanJson.containsKey('account_id'), isFalse);
    expect(loanJson.containsKey('lender_name'), isFalse);
    expect(loanJson.containsKey('start_date'), isFalse);
  });

  test('buildExportData includes transfers in export', () {
    stubEmptyRepos();
    final transfer = TransferModel.create(
      name: 'Epargne',
      amount: 500,
      fromAccountId: 1,
      toAccountId: 2,
      startDate: DateTime(2025, 3, 15),
      frequency: 'Mensuel',
    );
    transfer.id = 10;
    when(() => mockTransferRepo.getAll()).thenReturn([transfer]);

    final result = service.buildExportData();

    expect(result['transfers'], isA<List>());
    final transfers = result['transfers'] as List;
    expect(transfers, hasLength(1));
    expect(transfers.first['name'], 'Epargne');
    expect(transfers.first['amount'], 500.0);
    expect(transfers.first['fromAccountId'], '1');
    expect(transfers.first['toAccountId'], '2');
  });
}
