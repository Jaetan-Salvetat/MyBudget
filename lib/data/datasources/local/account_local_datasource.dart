import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/services/hive_service.dart';
import 'package:mybudget/data/datasources/local/base_local_datasource.dart';
import 'package:mybudget/data/models/account_model.dart';

final accountLocalDataSourceProvider = Provider<AccountLocalDataSource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return AccountLocalDataSource(hiveService);
});

class AccountLocalDataSource extends BaseLocalDataSource<AccountModel> {
  final HiveService _hiveService;
  
  AccountLocalDataSource(this._hiveService) : super('accounts');
  
  Future<void> initialize() async {
    await _hiveService.init();
  }
  
  Future<AccountModel> createAccount(String id, String name, String bank) async {
    final account = AccountModel(id: id, name: name, bank: bank);
    await create(account, id);
    return account;
  }
  
  Future<List<AccountModel>> getAccounts() async {
    return await getAll();
  }
  
  Future<AccountModel?> getAccount(String id) async {
    return await get(id);
  }
  
  Future<void> updateAccount(AccountModel account) async {
    await update(account.id, account);
  }
  
  Future<void> deleteAccount(String id) async {
    await delete(id);
  }
}
