import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/data/models/revenue_model.dart';
import 'package:mybudget/data/models/account_model.dart';

class IsarService {
  static late Isar isar;
  
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        CategoryModelSchema, 
        ExpenseModelSchema, 
        RevenueModelSchema,
        AccountModelSchema,
      ],
      directory: dir.path,
    );
  }
  
  // Categories
  Future<List<CategoryModel>> getAllCategories() async {
    return await isar.categoryModels.where().findAll();
  }
  
  Future<CategoryModel?> getCategoryById(int id) async {
    return await isar.categoryModels.get(id);
  }
  
  Future<void> saveCategory(CategoryModel category) async {
    await isar.writeTxn(() => isar.categoryModels.put(category));
  }
  
  Future<void> deleteCategory(int id) async {
    await isar.writeTxn(() => isar.categoryModels.delete(id));
  }
  
  // Expenses
  Future<List<ExpenseModel>> getAllExpenses() async {
    return await isar.expenseModels.where().findAll();
  }
  
  Future<ExpenseModel?> getExpenseById(int id) async {
    return await isar.expenseModels.get(id);
  }
  
  Future<void> saveExpense(ExpenseModel expense) async {
    await isar.writeTxn(() => isar.expenseModels.put(expense));
  }
  
  Future<void> deleteExpense(int id) async {
    await isar.writeTxn(() => isar.expenseModels.delete(id));
  }
  
  // Revenues
  Future<List<RevenueModel>> getAllRevenues() async {
    return await isar.revenueModels.where().findAll();
  }
  
  Future<RevenueModel?> getRevenueById(int id) async {
    return await isar.revenueModels.get(id);
  }
  
  Future<void> saveRevenue(RevenueModel revenue) async {
    await isar.writeTxn(() => isar.revenueModels.put(revenue));
  }
  
  Future<void> deleteRevenue(int id) async {
    await isar.writeTxn(() => isar.revenueModels.delete(id));
  }
  
  // Accounts
  Future<List<AccountModel>> getAllAccounts() async {
    return await isar.accountModels.where().findAll();
  }
  
  Future<AccountModel?> getAccountById(int id) async {
    return await isar.accountModels.get(id);
  }
  
  Future<void> saveAccount(AccountModel account) async {
    await isar.writeTxn(() => isar.accountModels.put(account));
  }
  
  Future<void> deleteAccount(int id) async {
    await isar.writeTxn(() => isar.accountModels.delete(id));
  }
  
  // Clear all data (for reset)
  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.categoryModels.clear();
      await isar.expenseModels.clear();
      await isar.revenueModels.clear();
      await isar.accountModels.clear();
    });
  }
}
