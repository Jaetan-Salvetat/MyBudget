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
    );
    final rev2 = RevenueModel.create(
      name: 'Freelance',
      amount: 500,
      accountId: 1,
      date: DateTime(2026, 6, 1),
    );
    final rev3 = RevenueModel.create(
      name: 'Bonus',
      amount: 300,
      accountId: 1,
      date: DateTime(2024, 12, 31),
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

  test('getRevenuesForAccount filters by accountId', () async {
    final rev1 = RevenueModel.create(
      name: 'Acc1 revenue',
      amount: 1000,
      accountId: 1,
      date: DateTime.now(),
    );
    final rev2 = RevenueModel.create(
      name: 'Acc2 revenue',
      amount: 500,
      accountId: 2,
      date: DateTime.now(),
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
