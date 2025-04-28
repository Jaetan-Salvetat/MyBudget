import 'package:mybudget/data/datasources/local_data_source.dart';
import 'package:mybudget/data/models/revenue_model.dart';
import 'package:mybudget/domain/entities/revenue.dart';
import 'package:mybudget/domain/repositories/revenue_repository.dart';

class RevenueRepositoryImpl implements RevenueRepository {
  final LocalDataSource localDataSource;
  RevenueRepositoryImpl(this.localDataSource);
  @override
  Future<void> addRevenue(Revenue revenue) async {
    final List<Revenue> revenues = await getRevenues();
    revenues.add(revenue);
    await localDataSource.saveData(
        key: 'revenues',
        value: revenues.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> deleteRevenue(String id) async {
    final List<Revenue> revenues = await getRevenues();
    revenues.removeWhere((revenue) => revenue.id == id);
    await localDataSource.saveData(
        key: 'revenues',
        value: revenues.map((e) => e.toJson()).toList());
  }

  @override
  Future<List<Revenue>> getRevenues() async {
    final List<dynamic> revenues =
        await localDataSource.getData(key: 'revenues') as List<dynamic>;
    return revenues.map((revenue) => RevenueModel.fromJson(revenue)).toList();
  }

  @override
  Future<void> updateRevenue(Revenue revenue) async {
    final List<Revenue> revenues = await getRevenues();
    revenues[revenues.indexWhere((element) => element.id == revenue.id)] = revenue;
    await localDataSource.saveData(key: 'revenues', value: revenues.map((e) => e.toJson()).toList());
  }
}
