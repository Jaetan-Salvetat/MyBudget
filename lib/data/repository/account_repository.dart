import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/objectbox.g.dart';

class AccountRepository {
  AccountRepository(Store store) : _box = Box<AccountModel>(store);

  final Box<AccountModel> _box;

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
