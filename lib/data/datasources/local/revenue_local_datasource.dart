import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/services/hive_service.dart';
import 'package:mybudget/data/datasources/local/base_local_datasource.dart';
import 'package:mybudget/data/models/revenue_model.dart';

final revenueLocalDataSourceProvider = Provider<RevenueLocalDataSource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return RevenueLocalDataSource(hiveService);
});

class RevenueLocalDataSource extends BaseLocalDataSource<RevenueModel> {
  final HiveService _hiveService;
  
  RevenueLocalDataSource(this._hiveService) : super('revenues');
  
  Future<void> initialize() async {
    await _hiveService.init();
  }
  
  Future<RevenueModel> createRevenue(
    String id,
    String name,
    double amount,
    bool isRegular,
    DateTime date,
    String accountId,
  ) async {
    final revenue = RevenueModel(
      id: id,
      name: name,
      amount: amount,
      isRegular: isRegular,
      date: date,
      accountId: accountId,
    );
    await create(revenue, id);
    return revenue;
  }
  
  Future<List<RevenueModel>> getRevenues() async {
    return await getAll();
  }
  
  Future<List<RevenueModel>> getRevenuesByAccount(String accountId) async {
    final revenues = await getAll();
    return revenues.where((revenue) => revenue.accountId == accountId).toList();
  }
  
  Future<RevenueModel?> getRevenue(String id) async {
    return await get(id);
  }
  
  Future<void> updateRevenue(RevenueModel revenue) async {
    await update(revenue.id, revenue);
  }
  
  Future<void> deleteRevenue(String id) async {
    await delete(id);
  }
}
