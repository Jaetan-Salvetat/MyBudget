import 'package:mybudget/models/account_model.dart';
import 'package:objectbox/objectbox.dart';

class AccountRepository {
  final Box<AccountModel> _box;

  AccountRepository(this._box);

  List<AccountModel> getAll() {
    return _box.getAll();
  }

  int add(AccountModel account) {
    return _box.put(account);
  }

  int update(AccountModel account) {
    return _box.put(account);
  }

  bool delete(int id) {
    return _box.remove(id);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
