import 'package:mybudget/core/usecases/usecase.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/repositories/account_repository.dart';

class GetAccountsUseCase extends UseCase<List<Account>, NoParams> {
  final AccountRepository repository;

  GetAccountsUseCase(this.repository);

  @override
  Future<List<Account>> call(NoParams params) async {
    return repository.getAccounts();
  }
}