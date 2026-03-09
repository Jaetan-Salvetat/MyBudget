import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/revenue_model.dart';

class MockRevenueRepository extends Mock implements RevenueRepository {}

void main() {
  late MockRevenueRepository mockRepository;

  setUp(() {
    mockRepository = MockRevenueRepository();
    when(() => mockRepository.getAll()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        revenueRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  }

  test(
    'getMonthlyRevenues should verify bounds correctly (Start and End of Month)',
    () async {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonthDate = DateTime(now.year, now.month + 1, 0, 23, 0);

      final revStart = RevenueModel.create(
        name: 'Start',
        amount: 100,
        accountId: 1,
        date: startOfMonth,
        isRegular: true,
      );
      final revEnd = RevenueModel.create(
        name: 'End',
        amount: 100,
        accountId: 1,
        date: endOfMonthDate,
        isRegular: true,
      );
      final revMiddle = RevenueModel.create(
        name: 'Mid',
        amount: 100,
        accountId: 1,
        date: startOfMonth.add(const Duration(days: 15)),
        isRegular: true,
      );
      final revPrevious = RevenueModel.create(
        name: 'Prev',
        amount: 100,
        accountId: 1,
        date: startOfMonth.subtract(const Duration(days: 1)),
        isRegular: true,
      );

      when(
        () => mockRepository.getAll(),
      ).thenReturn([revStart, revEnd, revMiddle, revPrevious]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(revenueProvider.future);

      final total = container.read(revenueProvider.notifier).getMonthlyRevenues();

      expect(
        total,
        300.0,
        reason: 'Should include revenues up to the last moment of the month',
      );
    },
  );

  test('getMonthlyFixedRevenues vs Punctual', () async {
    final fixed = RevenueModel.create(
      name: 'Fixed',
      amount: 1000,
      accountId: 1,
      date: DateTime.now(),
      isRegular: true,
    );
    final punctual = RevenueModel.create(
      name: 'Punctual',
      amount: 500,
      accountId: 1,
      date: DateTime.now(),
      isRegular: false,
    );

    when(() => mockRepository.getAll()).thenReturn([fixed, punctual]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(container.read(revenueProvider.notifier).getMonthlyFixedRevenues(), 1000.0);
    expect(container.read(revenueProvider.notifier).getMonthlyPunctualRevenues(), 500.0);
  });

  test('getMonthlyRevenues with empty list returns 0.0', () async {
    when(() => mockRepository.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(container.read(revenueProvider.notifier).getMonthlyRevenues(), 0.0);
  });

  test('getMonthlyFixedRevenues + getMonthlyPunctualRevenues equals getMonthlyRevenues', () async {
    final now = DateTime.now();
    final fixed = RevenueModel.create(
      name: 'Salary',
      amount: 2000,
      accountId: 1,
      date: now,
      isRegular: true,
    );
    final bonus = RevenueModel.create(
      name: 'Bonus',
      amount: 300,
      accountId: 1,
      date: now,
      isRegular: false,
    );

    when(() => mockRepository.getAll()).thenReturn([fixed, bonus]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    final notifier = container.read(revenueProvider.notifier);
    expect(
      notifier.getMonthlyFixedRevenues() + notifier.getMonthlyPunctualRevenues(),
      notifier.getMonthlyRevenues(),
    );
  });

  test('getMonthlyRevenues excludes revenue from previous month', () async {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 15);

    final oldRevenue = RevenueModel.create(
      name: 'Old salary',
      amount: 2000,
      accountId: 1,
      date: previousMonth,
      isRegular: true,
    );

    when(() => mockRepository.getAll()).thenReturn([oldRevenue]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(container.read(revenueProvider.notifier).getMonthlyRevenues(), 0.0);
  });

  test('getRevenuesForAccount filters by accountId', () async {
    final rev1 = RevenueModel.create(
      name: 'Acc1 revenue',
      amount: 1000,
      accountId: 1,
      date: DateTime.now(),
      isRegular: true,
    );
    final rev2 = RevenueModel.create(
      name: 'Acc2 revenue',
      amount: 500,
      accountId: 2,
      date: DateTime.now(),
      isRegular: true,
    );

    when(() => mockRepository.getAll()).thenReturn([rev1, rev2]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    final result = container.read(revenueProvider.notifier).getRevenuesForAccount(1);
    expect(result.length, 1);
    expect(result.first.name, 'Acc1 revenue');
  });
}
