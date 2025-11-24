import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/revenue_model.dart';

class MockRevenueRepository extends Mock implements RevenueRepository {}

void main() {
  late RevenueViewModel viewModel;
  late MockRevenueRepository mockRepository;

  setUp(() {
    mockRepository = MockRevenueRepository();
    when(() => mockRepository.getAll()).thenReturn([]);
    viewModel = RevenueViewModel(mockRepository);
  });

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

      await viewModel.loadRevenues();

      final total = viewModel.getMonthlyRevenues();

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
    await viewModel.loadRevenues();

    expect(viewModel.getMonthlyFixedRevenues(), 1000.0);
    expect(viewModel.getMonthlyPunctualRevenues(), 500.0);
  });
}
