import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/provider/beneficiary_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/repository/beneficiary_repository.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class FakeBeneficiaryModel extends Fake implements BeneficiaryModel {}

BeneficiaryModel _makeBeneficiary({
  int id = 1,
  String name = 'Paul',
  int color = 0xFF42A5F5,
}) {
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

      expect(
        container.read(beneficiaryProvider).value!.map((b) => b.name).toList(),
        ['Alice', 'Marc', 'Zoé'],
      );
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

      final result = await container
          .read(beneficiaryProvider.notifier)
          .addBeneficiary('');
      expect(result, 'Le nom ne peut pas être vide');
      verifyNever(() => mockBeneficiaryRepo.add(any()));
    });

    test('returns error for whitespace-only name', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .addBeneficiary('   ');
      expect(result, 'Le nom ne peut pas être vide');
      verifyNever(() => mockBeneficiaryRepo.add(any()));
    });

    test('returns error for duplicate name (case-insensitive)', () async {
      when(
        () => mockBeneficiaryRepo.getAll(),
      ).thenReturn([_makeBeneficiary(id: 1, name: 'Paul')]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .addBeneficiary('paul');
      expect(result, 'Ce bénéficiaire existe déjà');
      verifyNever(() => mockBeneficiaryRepo.add(any()));
    });

    test('adds beneficiary and returns null on success', () async {
      when(() => mockBeneficiaryRepo.add(any())).thenReturn(1);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .addBeneficiary('Marie');

      expect(result, isNull);
      verify(() => mockBeneficiaryRepo.add(any())).called(1);
    });

    test('trims whitespace from name before adding', () async {
      when(() => mockBeneficiaryRepo.add(any())).thenReturn(1);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .addBeneficiary('  Marie  ');

      expect(result, isNull);
      final captured = verify(
        () => mockBeneficiaryRepo.add(captureAny()),
      ).captured;
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
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
      );
      expense.beneficiaryId = 42;

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockRevenueRepo.getAll()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .deleteBeneficiary(42);

      expect(result, contains('1 transaction'));
      verifyNever(() => mockBeneficiaryRepo.delete(any()));
    });

    test('blocks deletion when beneficiary is used in revenues', () async {
      final revenue = RevenueModel.create(
        name: 'Loyer Paul',
        amount: 500,
        accountId: 1,
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
      );
      revenue.beneficiaryId = 42;

      when(() => mockExpenseRepo.getAll()).thenReturn([]);
      when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .deleteBeneficiary(42);

      expect(result, contains('1 transaction'));
      verifyNever(() => mockBeneficiaryRepo.delete(any()));
    });

    test('uses plural when multiple transactions use beneficiary', () async {
      final expense1 = ExpenseModel.create(
        name: 'Netflix',
        amount: 15,
        accountId: 1,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
      );
      expense1.beneficiaryId = 42;

      final expense2 = ExpenseModel.create(
        name: 'Spotify',
        amount: 10,
        accountId: 1,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
      );
      expense2.beneficiaryId = 42;

      when(() => mockExpenseRepo.getAll()).thenReturn([expense1, expense2]);
      when(() => mockRevenueRepo.getAll()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .deleteBeneficiary(42);

      expect(result, contains('2 transactions'));
    });

    test('deletes beneficiary and returns null when not in use', () async {
      when(() => mockExpenseRepo.getAll()).thenReturn([]);
      when(() => mockRevenueRepo.getAll()).thenReturn([]);
      when(() => mockBeneficiaryRepo.delete(42)).thenReturn(true);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .deleteBeneficiary(42);

      expect(result, isNull);
      verify(() => mockBeneficiaryRepo.delete(42)).called(1);
    });
  });

  group('renameBeneficiary', () {
    test('returns error for empty name', () async {
      when(
        () => mockBeneficiaryRepo.getAll(),
      ).thenReturn([_makeBeneficiary(id: 1, name: 'Paul')]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .renameBeneficiary(1, '  ');

      expect(result, 'Le nom ne peut pas être vide');
      verifyNever(() => mockBeneficiaryRepo.update(any()));
    });

    test('returns error when another beneficiary owns the name', () async {
      when(() => mockBeneficiaryRepo.getAll()).thenReturn([
        _makeBeneficiary(id: 1, name: 'Paul'),
        _makeBeneficiary(id: 2, name: 'Alice'),
      ]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .renameBeneficiary(1, 'alice');

      expect(result, 'Ce bénéficiaire existe déjà');
      verifyNever(() => mockBeneficiaryRepo.update(any()));
    });

    test('returns error when the beneficiary no longer exists', () async {
      when(() => mockBeneficiaryRepo.get(9)).thenReturn(null);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .renameBeneficiary(9, 'Marie');

      expect(result, 'Ce bénéficiaire n\'existe plus');
      verifyNever(() => mockBeneficiaryRepo.update(any()));
    });

    test('renames and keeps the identity of the beneficiary', () async {
      final model = _makeBeneficiary(id: 1, name: 'Paul');
      when(() => mockBeneficiaryRepo.getAll()).thenReturn([model]);
      when(() => mockBeneficiaryRepo.get(1)).thenReturn(model);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .renameBeneficiary(1, '  Paulette  ');

      expect(result, isNull);
      final updated =
          verify(() => mockBeneficiaryRepo.update(captureAny())).captured.last
              as BeneficiaryModel;
      expect(updated.id, 1);
      expect(updated.name, 'Paulette');
      expect(updated.color, model.color);
    });

    test('accepts renaming a beneficiary to its own name', () async {
      final model = _makeBeneficiary(id: 1, name: 'Paul');
      when(() => mockBeneficiaryRepo.getAll()).thenReturn([model]);
      when(() => mockBeneficiaryRepo.get(1)).thenReturn(model);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = await container
          .read(beneficiaryProvider.notifier)
          .renameBeneficiary(1, 'Paul');

      expect(result, isNull);
    });
  });

  group('usageCounts', () {
    test('counts expenses and revenues per beneficiary', () async {
      final expense = ExpenseModel.create(
        name: 'Netflix',
        amount: 15,
        accountId: 1,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
      );
      expense.beneficiaryId = 42;

      final revenue = RevenueModel.create(
        name: 'Loyer Paul',
        amount: 500,
        accountId: 1,
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
      );
      revenue.beneficiaryId = 7;

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockRevenueRepo.getAll()).thenReturn([revenue]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      expect(container.read(beneficiaryProvider.notifier).usageCounts(), {
        42: 1,
        7: 1,
      });
    });

    test('ignores transactions without a beneficiary', () async {
      final expense = ExpenseModel.create(
        name: 'Netflix',
        amount: 15,
        accountId: 1,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
      );

      when(() => mockExpenseRepo.getAll()).thenReturn([expense]);
      when(() => mockRevenueRepo.getAll()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      expect(
        container.read(beneficiaryProvider.notifier).usageCounts(),
        isEmpty,
      );
    });
  });

  group('getBeneficiaryById', () {
    test('returns beneficiary when found', () async {
      final b = _makeBeneficiary(id: 5, name: 'Alice');
      when(() => mockBeneficiaryRepo.get(5)).thenReturn(b);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = container
          .read(beneficiaryProvider.notifier)
          .getBeneficiaryById(5);

      expect(result, isNotNull);
      expect(result!.name, 'Alice');
    });

    test('returns null when repository throws', () async {
      when(() => mockBeneficiaryRepo.get(99)).thenThrow(Exception('Not found'));

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(beneficiaryProvider.future);

      final result = container
          .read(beneficiaryProvider.notifier)
          .getBeneficiaryById(99);

      expect(result, isNull);
    });
  });
}
