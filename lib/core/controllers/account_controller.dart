import 'package:get/get.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';

class AccountController extends GetxController {
  final RxList<AccountModel> accounts = <AccountModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    getAccounts();
  }
  
  Future<void> getAccounts() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final objectBoxService = Get.find<ObjectBoxService>();
      final accountsList = objectBoxService.accountBox.getAll();
      accounts.value = accountsList;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> addAccount(AccountModel account) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final objectBoxService = Get.find<ObjectBoxService>();
      objectBoxService.accountBox.put(account);
      await getAccounts();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateAccount(AccountModel account) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final objectBoxService = Get.find<ObjectBoxService>();
      objectBoxService.accountBox.put(account);
      await getAccounts();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteAccount(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final objectBoxService = Get.find<ObjectBoxService>();
      objectBoxService.accountBox.remove(id);
      await getAccounts();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  void reset() {
    accounts.clear();
    error.value = '';
  }
  
  double getAccountBalance(int accountId) {
    final revenueController = Get.find<RevenueController>();
    final expenseController = Get.find<ExpenseController>();
    final loanController = Get.find<LoanController>();
    
    final accountRevenues = revenueController.revenues
        .where((revenue) => revenue.accountId == accountId)
        .toList();
    
    final accountExpenses = expenseController.expenses
        .where((expense) => expense.accountId == accountId)
        .toList();
        
    final activeLoans = loanController.loans
        .where((loan) => loan.accountId == accountId && !loan.isCompleted())
        .toList();
    
    final totalRevenues = accountRevenues.fold<double>(
      0.0, 
      (sum, revenue) => sum + revenue.amount
    );
    
    final totalExpenses = accountExpenses.fold<double>(
      0.0, 
      (sum, expense) => sum + expense.amount
    );
    
    final totalLoanPayments = activeLoans.fold<double>(
      0.0,
      (sum, loan) => sum + loan.monthlyPayment
    );
    
    return totalRevenues - totalExpenses - totalLoanPayments;
  }
  
  double getTotalBalance() {
    double total = 0.0;
    
    for (final account in accounts) {
      total += getAccountBalance(account.id);
    }
    
    return total;
  }
  
  double getNetCashFlow() {
    final revenueController = Get.find<RevenueController>();
    final expenseController = Get.find<ExpenseController>();
    final loanController = Get.find<LoanController>();
    
    final monthlyRevenues = revenueController.getMonthlyRevenues();
    final monthlyExpenses = expenseController.getMonthlyExpenses();
    final monthlyLoanPayments = loanController.getTotalMonthlyPayments();
    
    return monthlyRevenues - (monthlyExpenses + monthlyLoanPayments);
  }
  
  double getSavingsRate() {
    final revenueController = Get.find<RevenueController>();
    final monthlyRevenues = revenueController.getMonthlyRevenues();
    
    if (monthlyRevenues <= 0) return 0.0;
    
    final netCashFlow = getNetCashFlow();
    return (netCashFlow / monthlyRevenues) * 100;
  }
  
  int getTotalTransactionsCount() {
    final expenseController = Get.find<ExpenseController>();
    final revenueController = Get.find<RevenueController>();
    final loanController = Get.find<LoanController>();
    
    return expenseController.expenses.length + 
           revenueController.revenues.length + 
           loanController.getActiveLoans().length;
  }
}
