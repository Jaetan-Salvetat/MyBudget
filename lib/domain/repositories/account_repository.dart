import '../entities/account.dart';

abstract class AccountRepository {
  Future<void> addAccount(Account account);
  Future<List<Account>> getAccounts();
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);
}
