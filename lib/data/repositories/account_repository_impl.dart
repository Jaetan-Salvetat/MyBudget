import 'package:mybudget/data/datasources/account_datasource.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountDatasource _accountDatasource;

  AccountRepositoryImpl() : _accountDatasource = AccountDatasource();

  @override
  Future<List<Account>> getAccounts() async {
    return await _accountDatasource.getAccounts();
  }

  @override
  Future<void> addAccount(Account account) async {
    if (account is AccountModel) {
      await _accountDatasource.createAccount(account);
    } else {
      final accountModel = AccountModel(
        id: account.id,
        name: account.name,
        bank: account.bank
      );
      await _accountDatasource.createAccount(accountModel);
    }
  }

  @override
  Future<void> updateAccount(Account account) async {
    if (account is AccountModel) {
      await _accountDatasource.updateAccount(account);
    } else {
      final accountModel = AccountModel(
        id: account.id,
        name: account.name,
        bank: account.bank
      );
      await _accountDatasource.updateAccount(accountModel);
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _accountDatasource.deleteAccount(id);
  }
}
