import 'package:mybudget/core/errors/failure.dart';

import 'package:mybudget/core/usecases/usecase.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/repositories/account_repository.dart';

class AddAccountUseCase extends UseCase<Account, AddAccountParams> {
  final AccountRepository repository;

  AddAccountUseCase(this.repository);

   @override
  Future<void> call(AddAccountParams params) async {
     await repository.addAccount(params.account);
  }
}

class AddAccountParams {
  final Account account;

  AddAccountParams(this.account);
}