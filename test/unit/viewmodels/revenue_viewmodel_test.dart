import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/revenue_model.dart';

class MockRevenueRepository extends Mock implements RevenueRepository {}

void main() {
  late RevenueViewModel viewModel;
  late MockRevenueRepository mockRevenueRepository;

  setUp(() {
    mockRevenueRepository = MockRevenueRepository();

    when(() => mockRevenueRepository.getAll()).thenReturn([]);

    viewModel = RevenueViewModel(mockRevenueRepository);
  });

  group('RevenueViewModel', () {
    test('initial load should fetch revenues', () async {
      verify(() => mockRevenueRepository.getAll()).called(1);
      expect(viewModel.revenues, isEmpty);
      expect(viewModel.isLoading, false);
    });

    test('addRevenue should call repository and reload', () async {
      final revenue = RevenueModel.create(
        name: 'New Revenue',
        amount: 100.0,
        isRegular: true,
        date: DateTime.now(),
        accountId: 1,
      );

      when(() => mockRevenueRepository.add(revenue)).thenReturn(1);
      when(() => mockRevenueRepository.getAll()).thenReturn([revenue]);

      await viewModel.addRevenue(revenue);

      verify(() => mockRevenueRepository.add(revenue)).called(1);
      verify(() => mockRevenueRepository.getAll()).called(2);
      expect(viewModel.revenues.length, 1);
    });

    test('deleteRevenue should call repository and reload', () async {
      when(() => mockRevenueRepository.delete(1)).thenReturn(true);

      await viewModel.deleteRevenue(1);

      verify(() => mockRevenueRepository.delete(1)).called(1);
      verify(() => mockRevenueRepository.getAll()).called(2);
    });

    test('getTotalRevenues should calculate correctly', () {
      final r1 = RevenueModel.create(
        name: 'R1',
        amount: 100.0,
        isRegular: true,
        date: DateTime.now(),
        accountId: 1,
      );
      final r2 = RevenueModel.create(
        name: 'R2',
        amount: 200.0,
        isRegular: false,
        date: DateTime.now(),
        accountId: 1,
      );

      when(() => mockRevenueRepository.getAll()).thenReturn([r1, r2]);
      viewModel = RevenueViewModel(mockRevenueRepository);

      expect(viewModel.getTotalRevenues(), 300.0);
    });
  });
}
