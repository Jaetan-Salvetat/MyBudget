import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/usecases/usecase.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/add_account_usecase.dart';
import '../../domain/usecases/get_accounts_usecase.dart';

class AccountNotifier extends StateNotifier<List<Account>> {
  final GetAccountsUseCase getAccountsUseCase;
  final AddAccountUseCase addAccountUseCase;

  AccountNotifier(this.getAccountsUseCase, this.addAccountUseCase) : super([]);

  Future<void> getAccounts() async {
    final accounts = await getAccountsUseCase(NoParams());
    state = accounts;
  }

  Future<void> addAccount(Account account) async {
    await addAccountUseCase(AddAccountParams(account: account));
    state = [...state, account];
  }
}