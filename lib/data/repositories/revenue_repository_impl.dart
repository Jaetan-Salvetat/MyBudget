import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/datasources/revenue_datasource.dart';
import 'package:mybudget/data/datasources/local/revenue_local_datasource.dart';
import 'package:mybudget/data/models/revenue_model.dart';
import 'package:mybudget/domain/entities/revenue.dart';
import 'package:mybudget/domain/repositories/revenue_repository.dart';
import 'package:uuid/uuid.dart';

final revenueRepositoryProvider = Provider<RevenueRepository>((ref) {
  final cloudDataSource = ref.watch(revenueDataSourceProvider);
  final localDataSource = ref.watch(revenueLocalDataSourceProvider);
  return RevenueRepositoryImpl(cloudDataSource, localDataSource);
});

class RevenueRepositoryImpl implements RevenueRepository {
  final RevenueDataSource _cloudDataSource;
  final RevenueLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();
  bool _isOnlineMode = false;

  RevenueRepositoryImpl(this._cloudDataSource, this._localDataSource);

  void setOnlineMode(bool isOnline) {
    _isOnlineMode = isOnline;
  }

  Future<Revenue> createRevenue(
    String name,
    double amount,
    bool isRegular,
    DateTime date,
    String accountId,
  ) async {
    final id = _uuid.v4();
    
    if (_isOnlineMode) {
      return RevenueModel(
        id: id,
        name: name,
        amount: amount,
        isRegular: isRegular,
        date: date,
        accountId: accountId,
      );
    } else {
      return await _localDataSource.createRevenue(
        id, name, amount, isRegular, date, accountId);
    }
  }

  @override
  Future<List<Revenue>> getRevenues() async {
    if (_isOnlineMode) {
      return [];
    } else {
      return await _localDataSource.getRevenues();
    }
  }

  Future<List<Revenue>> getRevenuesByAccount(String accountId) async {
    if (_isOnlineMode) {
      return [];
    } else {
      return await _localDataSource.getRevenuesByAccount(accountId);
    }
  }

  Future<Revenue?> getRevenue(String id) async {
    if (_isOnlineMode) {
      return null;
    } else {
      return await _localDataSource.getRevenue(id);
    }
  }

  @override
  Future<void> updateRevenue(Revenue revenue) async {
    final revenueModel = RevenueModel(
      id: revenue.id,
      name: revenue.name,
      amount: revenue.amount,
      isRegular: revenue.isRegular,
      date: revenue.date,
      accountId: revenue.accountId,
    );
    
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.updateRevenue(revenueModel);
    }
  }

  @override
  Future<void> deleteRevenue(String id) async {
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.deleteRevenue(id);
    }
  }
  
  @override
  Future<void> addRevenue(Revenue revenue) async {
    final revenueModel = RevenueModel(
      id: revenue.id,
      name: revenue.name,
      amount: revenue.amount,
      isRegular: revenue.isRegular,
      date: revenue.date,
      accountId: revenue.accountId,
    );
    
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.create(revenueModel, revenue.id);
    }
  }
}
