import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/data/model/category_memory_model.dart';
import 'package:mybudget/data/model/category_override_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/loan_event_model.dart';
import 'package:mybudget/data/model/loan_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/model/transfer_model.dart';
import 'package:mybudget/data/repository/account_repository.dart';
import 'package:mybudget/data/repository/beneficiary_repository.dart';
import 'package:mybudget/data/repository/category_memory_repository.dart';
import 'package:mybudget/data/repository/category_override_repository.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/loan_event_repository.dart';
import 'package:mybudget/data/repository/loan_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/data/repository/transfer_repository.dart';
import 'package:mybudget/data/service/data/data_export_service.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockTransferRepository extends Mock implements TransferRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockCategoryMemoryRepository extends Mock
    implements CategoryMemoryRepository {}

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

void main() {
  late DataExportService service;
  late MockAccountRepository mockAccountRepo;
  late MockBeneficiaryRepository mockBeneficiaryRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;
  late MockLoanEventRepository mockLoanEventRepo;
  late MockTransferRepository mockTransferRepo;
  late MockCategoryOverrideRepository mockCategoryOverrideRepo;
  late MockCategoryMemoryRepository mockCategoryMemoryRepo;

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();
    mockLoanEventRepo = MockLoanEventRepository();
    when(() => mockLoanEventRepo.getAll()).thenReturn([]);
    when(() => mockLoanEventRepo.deleteAll()).thenReturn(null);
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
      loanEventRepo: mockLoanEventRepo,
      transferRepo: mockTransferRepo,
      clock: () => _fixedNow,
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
    when(() => mockLoanEventRepo.getAll()).thenReturn([]);
    when(() => mockTransferRepo.getAll()).thenReturn([]);
  }

  test('buildExportData returns correct structure with metadata', () {
    stubEmptyRepos();

    final result = service.buildExportData();

    expect(result['version'], 3);
    expect(result['exportDate'], isNotNull);
    expect(result['filename'], startsWith('mybudget_backup_'));
    expect(result['filename'], endsWith('.json'));
    expect(result['accounts'], isA<List<Map<String, dynamic>>>());
    expect(result['beneficiaries'], isA<List<Map<String, dynamic>>>());
    expect(result['categoryOverrides'], isA<List<Map<String, dynamic>>>());
    expect(result['categoryMemory'], isA<List<Map<String, dynamic>>>());
    expect(result['expenses'], isA<List<Map<String, dynamic>>>());
    expect(result['revenues'], isA<List<Map<String, dynamic>>>());
    expect(result['loans'], isA<List<Map<String, dynamic>>>());
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
      frequency: Frequency.monthly,
    );
    expense.id = 4;
    final revenue = RevenueModel.create(
      name: 'Salaire',
      amount: 3000.0,
      accountId: 1,
      startDate: DateTime(2025, 1, 1),
      frequency: Frequency.monthly,
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

    expect(result['accounts'] as List<Map<String, dynamic>>, hasLength(1));
    expect(
      (result['accounts'] as List<Map<String, dynamic>>).first['name'],
      'Compte',
    );
    expect(
      (result['beneficiaries'] as List<Map<String, dynamic>>).first['name'],
      'Alice',
    );
    expect(
      (result['categoryOverrides'] as List<Map<String, dynamic>>).first['slug'],
      'loisirs.cinema_sortie',
    );
    expect(
      (result['categoryMemory'] as List<Map<String, dynamic>>).first['key'],
      'macdo',
    );
    expect(
      (result['expenses'] as List<Map<String, dynamic>>).first['name'],
      'Netflix',
    );
    expect(
      (result['revenues'] as List<Map<String, dynamic>>).first['name'],
      'Salaire',
    );
    expect(
      (result['loans'] as List<Map<String, dynamic>>).first['name'],
      'Prêt',
    );
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
    final loanJson = (result['loans'] as List<Map<String, dynamic>>).first;

    expect(loanJson.containsKey('accountId'), isTrue);
    expect(loanJson.containsKey('lenderName'), isTrue);
    expect(loanJson.containsKey('startDate'), isTrue);
    expect(loanJson.containsKey('account_id'), isFalse);
    expect(loanJson.containsKey('lender_name'), isFalse);
    expect(loanJson.containsKey('start_date'), isFalse);
  });

  test('buildExportData includes loan events in export', () {
    stubEmptyRepos();
    final event = LoanEventModel.create(
      loanId: 3,
      type: LoanEventType.earlyRepaymentPartial,
      date: DateTime(2026, 7, 5),
      amount: 5000,
      reamortizationMode: ReamortizationMode.reducePayment,
    );
    when(() => mockLoanEventRepo.getAll()).thenReturn([event]);

    final data = service.buildExportData();
    final exported =
        (data['loanEvents'] as List<Map<String, dynamic>>).first as Map;

    expect(exported['loanId'], '3');
    expect(exported['typeId'], 'earlyRepaymentPartial');
    expect(exported['amount'], 5000.0);
    expect(exported['reamortizationModeId'], 'reducePayment');
  });

  test('buildExportData includes transfers in export', () {
    stubEmptyRepos();
    final transfer = TransferModel.create(
      name: 'Epargne',
      amount: 500,
      fromAccountId: 1,
      toAccountId: 2,
      startDate: DateTime(2025, 3, 15),
      frequency: Frequency.monthly,
    );
    transfer.id = 10;
    when(() => mockTransferRepo.getAll()).thenReturn([transfer]);

    final result = service.buildExportData();

    expect(result['transfers'], isA<List<Map<String, dynamic>>>());
    final transfers = result['transfers'] as List<Map<String, dynamic>>;
    expect(transfers, hasLength(1));
    expect(transfers.first['name'], 'Epargne');
    expect(transfers.first['amount'], 500.0);
    expect(transfers.first['fromAccountId'], '1');
    expect(transfers.first['toAccountId'], '2');
  });
}
