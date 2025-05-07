import 'package:get/get.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
import 'package:mybudget/data/models/expense_model.dart';

class ExpenseController extends GetxController {
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    getExpenses();
  }
  
  Future<void> getExpenses() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final objectBoxService = Get.find<ObjectBoxService>();
      final expensesList = objectBoxService.expenseBox.getAll();
      expenses.value = expensesList;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final objectBoxService = Get.find<ObjectBoxService>();
      objectBoxService.expenseBox.put(expense);
      await getExpenses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final objectBoxService = Get.find<ObjectBoxService>();
      objectBoxService.expenseBox.put(expense);
      await getExpenses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteExpense(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final objectBoxService = Get.find<ObjectBoxService>();
      objectBoxService.expenseBox.remove(id);
      await getExpenses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  void reset() {
    expenses.clear();
    error.value = '';
  }
  
  double getMonthlyExpenses() {
    if (expenses.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return expenses
        .where(
          (expense) =>
              expense.date.isAtSameMomentAs(startOfMonth) ||
              expense.date.isAtSameMomentAs(endOfMonth) ||
              (expense.date.isAfter(startOfMonth) &&
              expense.date.isBefore(endOfMonth)),
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  List<ExpenseModel> getRecentExpenses(int count) {
    final sortedExpenses = [...expenses];
    sortedExpenses.sort((a, b) => b.date.compareTo(a.date));
    return sortedExpenses.take(count).toList();
  }
  
  double getTotalExpenses() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  List<ExpenseModel> getExpensesForAccount(int accountId) {
    return expenses.where((expense) => expense.accountId == accountId).toList();
  }
}
