import 'package:path_provider/path_provider.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:path/path.dart' as p;

import 'package:mybudget/objectbox.g.dart';

class ObjectBoxService {
  late Store store;

  late Box<CategoryModel> categoryBox;
  late Box<ExpenseModel> expenseBox;
  late Box<RevenueModel> revenueBox;
  late Box<AccountModel> accountBox;
  late Box<LoanModel> loanBox;

  static ObjectBoxService? _instance;

  ObjectBoxService._();

  static Future<ObjectBoxService> getInstance() async {
    if (_instance == null) {
      _instance = ObjectBoxService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = p.join(docsDir.path, "objectbox");
    store = await openStore(directory: storeDir);

    categoryBox = Box<CategoryModel>(store);
    expenseBox = Box<ExpenseModel>(store);
    revenueBox = Box<RevenueModel>(store);
    accountBox = Box<AccountModel>(store);
    loanBox = Box<LoanModel>(store);
  }

  void closeStore() {
    if (!store.isClosed()) {
      store.close();
    }
  }

  static Future<void> resetInstance() async {
    if (_instance != null) {
      _instance!.closeStore();
      _instance = null;
    }
  }

  Future<void> clearAllData() async {
    categoryBox.removeAll();
    expenseBox.removeAll();
    revenueBox.removeAll();
    accountBox.removeAll();
    loanBox.removeAll();
  }
}
