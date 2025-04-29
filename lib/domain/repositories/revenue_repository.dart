import '../entities/revenue.dart';

abstract class RevenueRepository {
  Future<void> addRevenue(Revenue revenue);
  Future<List<Revenue>> getRevenues();
  Future<void> updateRevenue(Revenue revenue);
  Future<void> deleteRevenue(String id);
}