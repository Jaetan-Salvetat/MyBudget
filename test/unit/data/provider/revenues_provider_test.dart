import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/provider/revenues_provider.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/data/repository/transaction_event_repository.dart';
import 'package:mybudget/ui/shared/revenue_queries.dart';

class MockRevenueRepository extends Mock implements RevenueRepository {}

class FakeRevenueModel extends Fake implements RevenueModel {}

class MockTransactionEventRepository extends Mock
    implements TransactionEventRepository {}

void main() {
  late MockRevenueRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeRevenueModel());
  });

  late MockTransactionEventRepository events;

  setUp(() {
    events = MockTransactionEventRepository();
    mockRepository = MockRevenueRepository();
    when(() => mockRepository.getChain(any())).thenReturn([]);
    when(() => mockRepository.getAll()).thenReturn([]);
    when(() => mockRepository.getActive()).thenReturn([]);
    when(() => mockRepository.getClosed()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        revenueRepositoryProvider.overrideWithValue(mockRepository),
        transactionEventRepositoryProvider.overrideWithValue(events),
      ],
    );
  }

  test('getMonthlyRevenues sums all revenues regardless of date', () async {
    final rev1 = RevenueModel.create(
      name: 'Salary',
      amount: 2000,
      accountId: 1,
      startDate: DateTime(2025, 1, 15),
      frequency: Frequency.monthly,
    );
    final rev2 = RevenueModel.create(
      name: 'Freelance',
      amount: 500,
      accountId: 1,
      startDate: DateTime(2026, 6, 1),
      frequency: Frequency.monthly,
    );
    final rev3 = RevenueModel.create(
      name: 'Bonus',
      amount: 300,
      accountId: 1,
      startDate: DateTime(2024, 12, 31),
      frequency: Frequency.monthly,
    );

    when(() => mockRepository.getAll()).thenReturn([rev1, rev2, rev3]);
    when(() => mockRepository.getActive()).thenReturn([rev1, rev2, rev3]);
    when(() => mockRepository.getClosed()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(container.read(monthlyRevenuesProvider), 2800.0);
  });

  test('getMonthlyRevenues with empty list returns 0.0', () async {
    when(() => mockRepository.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(container.read(monthlyRevenuesProvider), 0.0);
  });

  test(
    'getMonthlyRevenues includes annual revenue in matching month',
    () async {
      final now = DateTime.now();
      final rev = RevenueModel.create(
        name: 'Annual Bonus',
        amount: 6000,
        accountId: 1,
        startDate: DateTime(now.year, now.month, 15),
        frequency: Frequency.annual,
      );

      when(() => mockRepository.getAll()).thenReturn([rev]);
      when(() => mockRepository.getActive()).thenReturn([rev]);
      when(() => mockRepository.getClosed()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(revenueProvider.future);

      expect(container.read(monthlyRevenuesProvider), 6000.0);
    },
  );

  test(
    'getMonthlyRevenues excludes annual revenue in non-matching month',
    () async {
      final now = DateTime.now();
      final otherMonth = (now.month % 12) + 1;
      final rev = RevenueModel.create(
        name: 'Annual Bonus',
        amount: 6000,
        accountId: 1,
        startDate: DateTime(now.year, otherMonth, 15),
        frequency: Frequency.annual,
      );

      when(() => mockRepository.getAll()).thenReturn([rev]);
      when(() => mockRepository.getActive()).thenReturn([rev]);
      when(() => mockRepository.getClosed()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(revenueProvider.future);

      expect(container.read(monthlyRevenuesProvider), 0.0);
    },
  );

  test(
    'getMonthlyRevenues includes oneTime revenue in matching month',
    () async {
      final now = DateTime.now();
      final rev = RevenueModel.create(
        name: 'One-time Gift',
        amount: 1000,
        accountId: 1,
        startDate: DateTime(now.year, now.month, 10),
        frequency: Frequency.oneTime,
      );

      when(() => mockRepository.getAll()).thenReturn([rev]);
      when(() => mockRepository.getActive()).thenReturn([rev]);
      when(() => mockRepository.getClosed()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(revenueProvider.future);

      expect(container.read(monthlyRevenuesProvider), 1000.0);
    },
  );

  test(
    'getMonthlyRevenues excludes oneTime revenue in non-matching month',
    () async {
      final now = DateTime.now();
      final otherMonth = (now.month % 12) + 1;
      final rev = RevenueModel.create(
        name: 'One-time Gift',
        amount: 1000,
        accountId: 1,
        startDate: DateTime(now.year, otherMonth, 10),
        frequency: Frequency.oneTime,
      );

      when(() => mockRepository.getAll()).thenReturn([rev]);
      when(() => mockRepository.getActive()).thenReturn([rev]);
      when(() => mockRepository.getClosed()).thenReturn([]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(revenueProvider.future);

      expect(container.read(monthlyRevenuesProvider), 0.0);
    },
  );

  test('getMonthlyRevenues sums all 3 frequencies in matching month', () async {
    final now = DateTime.now();
    final monthly = RevenueModel.create(
      name: 'Salary',
      amount: 2000,
      accountId: 1,
      startDate: DateTime(now.year, now.month, 1),
      frequency: Frequency.monthly,
    );
    final annual = RevenueModel.create(
      name: 'Annual Bonus',
      amount: 3000,
      accountId: 1,
      startDate: DateTime(now.year, now.month, 15),
      frequency: Frequency.annual,
    );
    final oneTime = RevenueModel.create(
      name: 'Gift',
      amount: 500,
      accountId: 1,
      startDate: DateTime(now.year, now.month, 20),
      frequency: Frequency.oneTime,
    );

    when(() => mockRepository.getAll()).thenReturn([monthly, annual, oneTime]);
    when(
      () => mockRepository.getActive(),
    ).thenReturn([monthly, annual, oneTime]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(container.read(monthlyRevenuesProvider), 5500.0);
  });

  test('getRevenuesForAccount filters by accountId', () async {
    final rev1 = RevenueModel.create(
      name: 'Acc1 revenue',
      amount: 1000,
      accountId: 1,
      startDate: DateTime.now(),
      frequency: Frequency.monthly,
    );
    final rev2 = RevenueModel.create(
      name: 'Acc2 revenue',
      amount: 500,
      accountId: 2,
      startDate: DateTime.now(),
      frequency: Frequency.monthly,
    );

    when(() => mockRepository.getAll()).thenReturn([rev1, rev2]);
    when(() => mockRepository.getActive()).thenReturn([rev1, rev2]);
    when(() => mockRepository.getClosed()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    final result = container
        .read(revenueProvider.notifier)
        .getRevenuesForAccount(1);
    expect(result.length, 1);
    expect(result.first.name, 'Acc1 revenue');
  });

  test('deleteRevenue soft deletes recurring revenue', () async {
    final revenue = RevenueModel.create(
      name: 'Salaire',
      amount: 2000,
      accountId: 1,
      startDate: DateTime(2024, 6, 15),
      frequency: Frequency.monthly,
    )..id = 1;

    when(() => mockRepository.get(1)).thenReturn(revenue);
    when(() => mockRepository.update(any())).thenReturn(1);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);
    await container.read(revenueProvider.notifier).deleteRevenue(1);

    verify(() => mockRepository.update(any())).called(1);
    verifyNever(() => mockRepository.delete(any()));
  });

  test('deleteRevenue hard deletes oneTime revenue', () async {
    final revenue = RevenueModel.create(
      name: 'Prime unique',
      amount: 500,
      accountId: 1,
      startDate: DateTime(2024, 6, 15),
      frequency: Frequency.oneTime,
    )..id = 2;

    when(() => mockRepository.get(2)).thenReturn(revenue);
    when(() => mockRepository.delete(2)).thenReturn(true);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);
    await container.read(revenueProvider.notifier).deleteRevenue(2);

    verify(() => mockRepository.delete(2)).called(1);
    verifyNever(() => mockRepository.update(any()));
  });

  test('updateRevenue with category-only change propagates to chain', () async {
    final existing = RevenueModel.create(
      name: 'Ancien nom',
      amount: 1000,
      accountId: 1,
      startDate: DateTime(2024, 6, 15),
      frequency: Frequency.monthly,
    )..id = 1;

    final chainEntry = RevenueModel.create(
      name: 'Ancien nom',
      amount: 1000,
      accountId: 1,
      startDate: DateTime(2024, 8, 15),
      frequency: Frequency.monthly,
      parentId: 1,
    )..id = 2;

    when(() => mockRepository.get(1)).thenReturn(existing);
    when(() => mockRepository.getChain(1)).thenReturn([existing, chainEntry]);
    when(() => mockRepository.update(any())).thenReturn(1);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    final updated = existing.copyWith(categorySlug: 'finance.frais_bancaires');
    await container.read(revenueProvider.notifier).updateRevenue(updated);

    verify(() => mockRepository.getChain(1)).called(1);
    verify(() => mockRepository.update(any())).called(2);
    verifyNever(() => mockRepository.add(any()));
  });

  test(
    'updateRevenue with structural change on recurring closes old and creates new',
    () async {
      final existing = RevenueModel.create(
        name: 'Salaire',
        amount: 2000,
        accountId: 1,
        startDate: DateTime(2024, 6, 15),
        frequency: Frequency.monthly,
      )..id = 1;

      when(() => mockRepository.get(1)).thenReturn(existing);
      when(() => mockRepository.update(any())).thenReturn(1);
      when(() => mockRepository.add(any())).thenReturn(2);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(revenueProvider.future);

      final updated = existing.copyWith(amount: 2500);
      await container.read(revenueProvider.notifier).updateRevenue(updated);

      verify(() => mockRepository.update(any())).called(1);
      verify(() => mockRepository.add(any())).called(1);
    },
  );

  test(
    'updateRevenue with structural change on oneTime does simple update',
    () async {
      final existing = RevenueModel.create(
        name: 'Prime',
        amount: 500,
        accountId: 1,
        startDate: DateTime(2024, 6, 15),
        frequency: Frequency.oneTime,
      )..id = 1;

      when(() => mockRepository.get(1)).thenReturn(existing);
      when(() => mockRepository.update(any())).thenReturn(1);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(revenueProvider.future);

      final updated = existing.copyWith(amount: 600);
      await container.read(revenueProvider.notifier).updateRevenue(updated);

      verify(() => mockRepository.update(any())).called(1);
      verifyNever(() => mockRepository.add(any()));
    },
  );

  test('getClosedRevenues returns closed entries', () async {
    final closed = RevenueModel.create(
      name: 'Ancien revenu',
      amount: 1000,
      accountId: 1,
      startDate: DateTime(2024, 1, 15),
      frequency: Frequency.monthly,
      endDate: DateTime(2024, 6, 15),
    )..id = 1;

    when(() => mockRepository.getClosed()).thenReturn([closed]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    final result = container.read(revenueProvider.notifier).getClosedRevenues();

    expect(result.length, 1);
    expect(result.first.endDate, isNotNull);
  });
}
