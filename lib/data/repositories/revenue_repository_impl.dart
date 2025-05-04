import 'package:mybudget/data/datasources/revenue_datasource.dart';
import 'package:mybudget/data/models/revenue_model.dart';
import 'package:mybudget/domain/entities/revenue.dart';
import 'package:mybudget/domain/repositories/revenue_repository.dart';

class RevenueRepositoryImpl implements RevenueRepository {
  final RevenueDatasource _revenueDatasource;

  RevenueRepositoryImpl() : _revenueDatasource = RevenueDatasource();

  @override
  Future<List<Revenue>> getRevenues() async {
    return await _revenueDatasource.getRevenues();
  }
  
  @override
  Future<void> addRevenue(Revenue revenue) async {
    if (revenue is RevenueModel) {
      await _revenueDatasource.createRevenue(revenue);
    } else {
      final revenueModel = RevenueModel(
        id: revenue.id,
        name: revenue.name,
        amount: revenue.amount,
        isRegular: revenue.isRegular,
        date: revenue.date,
        accountId: revenue.accountId
      );
      await _revenueDatasource.createRevenue(revenueModel);
    }
  }

  @override
  Future<void> updateRevenue(Revenue revenue) async {
    if (revenue is RevenueModel) {
      await _revenueDatasource.updateRevenue(revenue);
    } else {
      final revenueModel = RevenueModel(
        id: revenue.id,
        name: revenue.name,
        amount: revenue.amount,
        isRegular: revenue.isRegular,
        date: revenue.date,
        accountId: revenue.accountId
      );
      await _revenueDatasource.updateRevenue(revenueModel);
    }
  }

  @override
  Future<void> deleteRevenue(String id) async {
    await _revenueDatasource.deleteRevenue(id);
  }
}
