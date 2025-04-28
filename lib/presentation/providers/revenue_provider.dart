import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/usecases/usecase.dart';
import '../../../domain/entities/revenue.dart';
import '../../../domain/usecases/add_revenue_usecase.dart';
import '../../../domain/usecases/get_revenues_usecase.dart';

class RevenueNotifier extends StateNotifier<List<Revenue>> {
  final GetRevenuesUseCase getRevenuesUseCase;
  final AddRevenueUseCase addRevenueUseCase;
  RevenueNotifier({required this.getRevenuesUseCase, required this.addRevenueUseCase}) : super([]);

  Future<void> getRevenues() async {
    state = await getRevenuesUseCase(NoParams());
  }

  Future<void> addRevenue(Revenue revenue) async {
    await addRevenueUseCase(AddRevenueParams(revenue: revenue));
    getRevenues();
  }
}