import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../data/repositories/account_repository_impl.dart';

final accountNotifierProvider = StateNotifierProvider<AccountNotifier, List<Account>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return AccountNotifier(repository);
});

class AccountNotifier extends StateNotifier<List<Account>> {
  final AccountRepository _repository;

  AccountNotifier(this._repository) : super([]) {
    getAccounts();
  }

  Future<void> getAccounts() async {
    final accounts = await _repository.getAccounts();
    state = accounts;
  }

  void addAccount(Account account) async {
    await _repository.addAccount(account);
    await getAccounts();
  }
  
  void updateAccount(Account account) async {
    await _repository.updateAccount(account);
    await getAccounts();
  }
  
  void deleteAccount(String id) async {
    await _repository.deleteAccount(id);
    await getAccounts();
  }
}
