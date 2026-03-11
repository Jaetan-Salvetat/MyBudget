import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class FakeBeneficiaryModel extends Fake implements BeneficiaryModel {}

BeneficiaryModel _makeBeneficiary({int id = 1, String name = 'Paul', int color = 0xFF42A5F5}) {
  final b = BeneficiaryModel.create(name: name, color: color);
  b.id = id;
  return b;
}

void main() {
  late MockBeneficiaryRepository mockBeneficiaryRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockRevenueRepository mockRevenueRepo;

  setUpAll(() {
    registerFallbackValue(FakeBeneficiaryModel());
  });

  setUp(() {
    mockBeneficiaryRepo = MockBeneficiaryRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockRevenueRepo = MockRevenueRepository();

    when(() => mockBeneficiaryRepo.getAll()).thenReturn([]);
    when(() => mockBeneficiaryRepo.update(any())).thenReturn(1);
    when(() => mockExpenseRepo.getAll()).thenReturn([]);
    when(() => mockRevenueRepo.getAll()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        beneficiaryRepositoryProvider.overrideWithValue(mockBeneficiaryRepo),
        expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
        revenueRepositoryProvider.overrideWithValue(mockRevenueRepo),
      ],
    );
  }

  group('loadBeneficiaries', () {
    test('loads beneficiaries sorted alphabetically', () async {
      when(() => mockBeneficiaryRepo.getAll()).thenReturn([
        _makeBeneficiary(id: 1, name: 'Zoé'),
        _makeBeneficiary(id: 2, name: 'Alice'),
        _makeBeneficiary(id: 3, name: 'Marc'),
      ]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      expect(container.read(beneficiaryProvider).value!.map((b) => b.name).toList(), [
        'Alice',
        'Marc',
        'Zoé',
      ]);
    });

    test('provider resolves after load', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);
      expect(container.read(beneficiaryProvider).hasValue, true);
    });
  });

  group('addBeneficiary', () {
    test('returns error for empty name', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).addBeneficiary('');
      expect(result, 'Le nom ne peut pas être vide');
      verifyNever(() => mockBeneficiaryRepo.add(any()));
    });

    test('returns error for whitespace-only name', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).addBeneficiary('   ');
      expect(result, 'Le nom ne peut pas être vide');
      verifyNever(() => mockBeneficiaryRepo.add(any()));
    });

    test('returns error for duplicate name (case-insensitive)', () async {
      when(() => mockBeneficiaryRepo.getAll()).thenReturn([
        _makeBeneficiary(id: 1, name: 'Paul'),
      ]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).addBeneficiary('paul');
      expect(result, 'Ce bénéficiaire existe déjà');
      verifyNever(() => mockBeneficiaryRepo.add(any()));
    });

    test('adds beneficiary and returns null on success', () async {
      when(() => mockBeneficiaryRepo.add(any())).thenReturn(1);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).addBeneficiary('Marie');

      expect(result, isNull);
      verify(() => mockBeneficiaryRepo.add(any())).called(1);
    });

    test('trims whitespace from name before adding', () async {
      when(() => mockBeneficiaryRepo.add(any())).thenReturn(1);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).addBeneficiary('  Marie  ');

      expect(result, isNull);
      final captured =
          verify(() => mockBeneficiaryRepo.add(captureAny())).captured;
      final added = captured.first as BeneficiaryModel;
      expect(added.name, 'Marie');
    });
  });

  group('deleteBeneficiary', () {
    test('blocks deletion when beneficiary is used in expenses', () async {
      final expense = ExpenseModel.create(
        name: 'Netflix',
        amount: 15,
        accountId: 1,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
      );
      expense.beneficiaryId = 42;

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockRevenueRepo.getAll()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).deleteBeneficiary(42);

      expect(result, contains('1 transaction'));
      verifyNever(() => mockBeneficiaryRepo.delete(any()));
    });

    test('blocks deletion when beneficiary is used in revenues', () async {
      final revenue = RevenueModel.create(
        name: 'Loyer Paul',
        amount: 500,
        accountId: 1,
        date: DateTime.now(),

      );
      revenue.beneficiaryId = 42;

      when(() => mockExpenseRepo.getAll()).thenReturn([]);
      when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).deleteBeneficiary(42);

      expect(result, contains('1 transaction'));
      verifyNever(() => mockBeneficiaryRepo.delete(any()));
    });

    test('uses plural when multiple transactions use beneficiary', () async {
      final expense1 = ExpenseModel.create(
        name: 'Netflix',
        amount: 15,
        accountId: 1,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
      );
      expense1.beneficiaryId = 42;

      final expense2 = ExpenseModel.create(
        name: 'Spotify',
        amount: 10,
        accountId: 1,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
      );
      expense2.beneficiaryId = 42;

      when(() => mockExpenseRepo.getAll()).thenReturn([expense1, expense2]);
      when(() => mockRevenueRepo.getAll()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).deleteBeneficiary(42);

      expect(result, contains('2 transactions'));
    });

    test('deletes beneficiary and returns null when not in use', () async {
      when(() => mockExpenseRepo.getAll()).thenReturn([]);
      when(() => mockRevenueRepo.getAll()).thenReturn([]);
      when(() => mockBeneficiaryRepo.delete(42)).thenReturn(true);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container.read(beneficiaryProvider.notifier).deleteBeneficiary(42);

      expect(result, isNull);
      verify(() => mockBeneficiaryRepo.delete(42)).called(1);
    });
  });

  group('getBeneficiaryById', () {
    test('returns beneficiary when found', () async {
      final b = _makeBeneficiary(id: 5, name: 'Alice');
      when(() => mockBeneficiaryRepo.get(5)).thenReturn(b);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = container.read(beneficiaryProvider.notifier).getBeneficiaryById(5);

      expect(result, isNotNull);
      expect(result!.name, 'Alice');
    });

    test('returns null when repository throws', () async {
      when(() => mockBeneficiaryRepo.get(99)).thenThrow(Exception('Not found'));

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = container.read(beneficiaryProvider.notifier).getBeneficiaryById(99);

      expect(result, isNull);
    });
  });
}
