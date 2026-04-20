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

  test('getMonthlyRevenues sums all revenues regardless of date', () async {
    final rev1 = RevenueModel.create(
      name: 'Salary',
      amount: 2000,
      accountId: 1,
      date: DateTime(2025, 1, 15),
      frequency: 'Mensuel',
    );
    final rev2 = RevenueModel.create(
      name: 'Freelance',
      amount: 500,
      accountId: 1,
      date: DateTime(2026, 6, 1),
      frequency: 'Mensuel',
    );
    final rev3 = RevenueModel.create(
      name: 'Bonus',
      amount: 300,
      accountId: 1,
      date: DateTime(2024, 12, 31),
      frequency: 'Mensuel',
    );

    when(() => mockRepository.getAll()).thenReturn([rev1, rev2, rev3]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(
      container.read(revenueProvider.notifier).getMonthlyRevenues(),
      2800.0,
    );
  });

  test('getMonthlyRevenues with empty list returns 0.0', () async {
    when(() => mockRepository.getAll()).thenReturn([]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(container.read(revenueProvider.notifier).getMonthlyRevenues(), 0.0);
  });

  test('getMonthlyRevenues includes annual revenue in matching month', () async {
    final now = DateTime.now();
    final rev = RevenueModel.create(
      name: 'Annual Bonus',
      amount: 6000,
      accountId: 1,
      date: DateTime(now.year, now.month, 15),
      frequency: 'Annuel',
    );

    when(() => mockRepository.getAll()).thenReturn([rev]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(
      container.read(revenueProvider.notifier).getMonthlyRevenues(),
      6000.0,
    );
  });

  test('getMonthlyRevenues excludes annual revenue in non-matching month', () async {
    final now = DateTime.now();
    final otherMonth = (now.month % 12) + 1;
    final rev = RevenueModel.create(
      name: 'Annual Bonus',
      amount: 6000,
      accountId: 1,
      date: DateTime(now.year, otherMonth, 15),
      frequency: 'Annuel',
    );

    when(() => mockRepository.getAll()).thenReturn([rev]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(
      container.read(revenueProvider.notifier).getMonthlyRevenues(),
      0.0,
    );
  });

  test('getMonthlyRevenues includes oneTime revenue in matching month', () async {
    final now = DateTime.now();
    final rev = RevenueModel.create(
      name: 'One-time Gift',
      amount: 1000,
      accountId: 1,
      date: DateTime(now.year, now.month, 10),
      frequency: 'Ponctuel',
    );

    when(() => mockRepository.getAll()).thenReturn([rev]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(
      container.read(revenueProvider.notifier).getMonthlyRevenues(),
      1000.0,
    );
  });

  test('getMonthlyRevenues excludes oneTime revenue in non-matching month', () async {
    final now = DateTime.now();
    final otherMonth = (now.month % 12) + 1;
    final rev = RevenueModel.create(
      name: 'One-time Gift',
      amount: 1000,
      accountId: 1,
      date: DateTime(now.year, otherMonth, 10),
      frequency: 'Ponctuel',
    );

    when(() => mockRepository.getAll()).thenReturn([rev]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(
      container.read(revenueProvider.notifier).getMonthlyRevenues(),
      0.0,
    );
  });

  test('getMonthlyRevenues sums all 3 frequencies in matching month', () async {
    final now = DateTime.now();
    final monthly = RevenueModel.create(
      name: 'Salary',
      amount: 2000,
      accountId: 1,
      date: DateTime(now.year, now.month, 1),
      frequency: 'Mensuel',
    );
    final annual = RevenueModel.create(
      name: 'Annual Bonus',
      amount: 3000,
      accountId: 1,
      date: DateTime(now.year, now.month, 15),
      frequency: 'Annuel',
    );
    final oneTime = RevenueModel.create(
      name: 'Gift',
      amount: 500,
      accountId: 1,
      date: DateTime(now.year, now.month, 20),
      frequency: 'Ponctuel',
    );

    when(() => mockRepository.getAll()).thenReturn([monthly, annual, oneTime]);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(revenueProvider.future);

    expect(
      container.read(revenueProvider.notifier).getMonthlyRevenues(),
      5500.0,
    );
  });

  test('getRevenuesForAccount filters by accountId', () async {
    final rev1 = RevenueModel.create(
      name: 'Acc1 revenue',
      amount: 1000,
      accountId: 1,
      date: DateTime.now(),
      frequency: 'Mensuel',
    );
    final rev2 = RevenueModel.create(
      name: 'Acc2 revenue',
      amount: 500,
      accountId: 2,
      date: DateTime.now(),
      frequency: 'Mensuel',
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
