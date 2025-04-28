import 'package:mybudget/core/usecases/usecase.dart';
import 'package:mybudget/core/usecases/usecase.dart';
import 'package:mybudget/domain/entities/revenue.dart';
import 'package:mybudget/domain/repositories/revenue_repository.dart';

class AddRevenueUseCase implements UseCase<void, AddRevenueParams> {
  final RevenueRepository revenueRepository;

  AddRevenueUseCase(this.revenueRepository);

  @override
  Future<void> call(AddRevenueParams params) async {
    await revenueRepository.addRevenue(params.revenue);
  }
}

class AddRevenueParams {
  final Revenue revenue;

  AddRevenueParams(this.revenue);

  
}