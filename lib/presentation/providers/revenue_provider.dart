import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/revenue.dart';
import '../../domain/repositories/revenue_repository.dart';
import '../../data/repositories/revenue_repository_impl.dart';


final revenueNotifierProvider = StateNotifierProvider<RevenueNotifier, List<Revenue>>(
  (ref) {
    final repository = ref.watch(revenueRepositoryProvider);
    return RevenueNotifier(repository);
  }
);

class RevenueNotifier extends StateNotifier<List<Revenue>> {
  final RevenueRepository _repository;

  RevenueNotifier(this._repository) : super([]) {
    getRevenues();
  }

  Future<void> getRevenues() async {
    final revenues = await _repository.getRevenues();
    state = revenues;
  }

  Future<void> addRevenue(Revenue revenue) async {
    await _repository.addRevenue(revenue);
    await getRevenues();
  }
  
  Future<void> updateRevenue(Revenue revenue) async {
    await _repository.updateRevenue(revenue);
    await getRevenues();
  }
  
  Future<void> deleteRevenue(String id) async {
    await _repository.deleteRevenue(id);
    await getRevenues();
  }
}
