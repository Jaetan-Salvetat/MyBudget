import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/datasources/account_datasource.dart';
import 'package:mybudget/data/datasources/local/account_local_datasource.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/repositories/account_repository.dart';
import 'package:uuid/uuid.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final cloudDataSource = ref.watch(accountDataSourceProvider);
  final localDataSource = ref.watch(accountLocalDataSourceProvider);
  return AccountRepositoryImpl(cloudDataSource, localDataSource);
});

class AccountRepositoryImpl implements AccountRepository {
  final AccountDataSource _cloudDataSource;
  final AccountLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();
  bool _isOnlineMode = false;

  AccountRepositoryImpl(this._cloudDataSource, this._localDataSource);

  void setOnlineMode(bool isOnline) {
    _isOnlineMode = isOnline;
  }

  Future<Account> createAccount(String name, String bank) async {
    final id = _uuid.v4();
    
    if (_isOnlineMode) {
      return AccountModel(id: id, name: name, bank: bank);
    } else {
      return await _localDataSource.createAccount(id, name, bank);
    }
  }

  @override
  Future<List<Account>> getAccounts() async {
    if (_isOnlineMode) {
      return [];
    } else {
      return await _localDataSource.getAccounts();
    }
  }

  Future<Account?> getAccount(String id) async {
    if (_isOnlineMode) {
      return null;
    } else {
      return await _localDataSource.getAccount(id);
    }
  }

  @override
  Future<void> updateAccount(Account account) async {
    final accountModel = AccountModel(
      id: account.id,
      name: account.name,
      bank: account.bank
    );
    
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.updateAccount(accountModel);
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.deleteAccount(id);
    }
  }
  
  @override
  Future<void> addAccount(Account account) async {
    final accountModel = AccountModel(
      id: account.id,
      name: account.name,
      bank: account.bank
    );
    
    if (_isOnlineMode) {
      return;
    } else {
      await _localDataSource.create(accountModel, account.id);
    }
  }
}
