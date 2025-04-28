import 'package:mybudget/data/datasources/local_data_source.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final LocalDataSource localDataSource;

  const AccountRepositoryImpl(this.localDataSource);

  @override
  Future<void> addAccount(Account account) async {
    final List<Account> accounts = await getAccounts();
    accounts.add(account);
    await localDataSource.saveData(
        key: 'accounts',
        value: accounts.map((e) => AccountModel.fromJson(e.toJson())).toList());
  }

  @override
  Future<List<Account>> getAccounts() async {
    final List<dynamic> accounts =
        await localDataSource.getData(key: 'accounts') as List<dynamic>;
    return accounts.map((account) => AccountModel.fromJson(account)).toList();
  }
}