import 'package:mybudget/core/errors/failure.dart';
import 'package:mybudget/core/usecases/usecase.dart';
import 'package:mybudget/domain/entities/revenue.dart';
import 'package:mybudget/domain/repositories/revenue_repository.dart';

class GetRevenuesUseCase implements UseCase<List<Revenue>, NoParams> {
  final RevenueRepository revenueRepository;

  GetRevenuesUseCase(this.revenueRepository);

  @override
  Future<List<Revenue>> call(NoParams params) async {
    return await revenueRepository.getRevenues();
  }
}