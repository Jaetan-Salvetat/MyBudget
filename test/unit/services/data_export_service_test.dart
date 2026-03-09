import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/data/data_export_service.dart';
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

void main() {
  late DataExportService service;
  late MockAccountRepository mockAccountRepo;
  late MockBeneficiaryRepository mockBeneficiaryRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;
  late MockLoanRepository mockLoanRepo;

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();
    mockLoanRepo = MockLoanRepository();

    service = DataExportService(
      accountRepo: mockAccountRepo,
      beneficiaryRepo: mockBeneficiaryRepo,
      categoryRepo: mockCategoryRepo,
      expenseRepo: mockExpenseRepo,
      revenueRepo: mockRevenueRepo,
      loanRepo: mockLoanRepo,
    );
  });

  void stubEmptyRepos() {
    when(() => mockAccountRepo.getAll()).thenReturn([]);
    when(() => mockBeneficiaryRepo.getAll()).thenReturn([]);
    when(() => mockCategoryRepo.getAll()).thenReturn([]);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
    when(() => mockLoanRepo.getAll()).thenReturn([]);
  }

  test('buildExportData returns correct structure with metadata', () {
    stubEmptyRepos();

    final result = service.buildExportData();

    expect(result['version'], 1);
    expect(result['exportDate'], isNotNull);
    expect(result['filename'], startsWith('mybudget_backup_'));
    expect(result['filename'], endsWith('.json'));
    expect(result['accounts'], isA<List>());
    expect(result['beneficiaries'], isA<List>());
    expect(result['categories'], isA<List>());
    expect(result['expenses'], isA<List>());
    expect(result['revenues'], isA<List>());
    expect(result['loans'], isA<List>());
  });

  test('buildExportData serializes all entities via toJson()', () {
    final account = AccountModel.create(name: 'Compte', bank: 'BNP');
    account.id = 1;
    final beneficiary = BeneficiaryModel.create(name: 'Alice');
    beneficiary.id = 2;
    final category = CategoryModel.create(name: 'Loisirs', icon: 'movie');
    category.id = 3;
    final expense = ExpenseModel.create(
      name: 'Netflix',
      amount: 15.0,
      categoryId: 3,
      accountId: 1,
      date: DateTime(2025, 1, 15),
      frequency: 'Mensuel',
    );
    expense.id = 4;
    final revenue = RevenueModel.create(
      name: 'Salaire',
      amount: 3000.0,
      accountId: 1,
      isRegular: true,
      date: DateTime(2025, 1, 1),
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
    when(() => mockCategoryRepo.getAll()).thenReturn([category]);
    when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
    when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);
    when(() => mockLoanRepo.getAll()).thenReturn([loan]);

    final result = service.buildExportData();

    expect((result['accounts'] as List), hasLength(1));
    expect((result['accounts'] as List).first['name'], 'Compte');
    expect((result['beneficiaries'] as List).first['name'], 'Alice');
    expect((result['categories'] as List).first['name'], 'Loisirs');
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

    // Vérifie camelCase (nouveau format), pas snake_case (ancien)
    expect(loanJson.containsKey('accountId'), isTrue);
    expect(loanJson.containsKey('lenderName'), isTrue);
    expect(loanJson.containsKey('startDate'), isTrue);
    expect(loanJson.containsKey('account_id'), isFalse);
    expect(loanJson.containsKey('lender_name'), isFalse);
    expect(loanJson.containsKey('start_date'), isFalse);
  });
}
