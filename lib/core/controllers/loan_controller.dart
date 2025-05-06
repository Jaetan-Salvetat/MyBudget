import 'package:get/get.dart';
import 'package:mybudget/core/services/isar_service.dart';
import 'package:mybudget/data/models/loan_model.dart';

class LoanController extends GetxController {
  final _isarService = Get.find<IsarService>();
  final loans = <LoanModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLoans();
  }

  Future<void> fetchLoans() async {
    isLoading.value = true;

    try {
      final loansList = await _isarService.getLoans();
      loans.value = loansList;
    } catch (error) {
      print('Error fetching loans: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addLoan(LoanModel loan) async {
    try {
      await _isarService.saveLoan(loan);
      await fetchLoans();
    } catch (error) {
      print('Error adding loan: $error');
    }
  }

  Future<void> updateLoan(LoanModel loan) async {
    try {
      await _isarService.saveLoan(loan);
      await fetchLoans();
    } catch (error) {
      print('Error updating loan: $error');
    }
  }

  Future<void> deleteLoan(int id) async {
    try {
      await _isarService.deleteLoan(id);
      await fetchLoans();
    } catch (error) {
      print('Error deleting loan: $error');
    }
  }

  double getTotalRemainingAmount() {
    final activeLoans = getActiveLoans();
    return activeLoans.fold(0.0, (sum, loan) => sum + loan.getRemainingAmount());
  }

  List<LoanModel> getActiveLoans() {
    return loans
        .where((loan) => loan.getAutomaticStatus() != LoanStatus.completed)
        .toList();
  }
  
  double getTotalMonthlyPayments() {
    final activeLoans = getActiveLoans();
    return activeLoans.fold(0.0, (sum, loan) => sum + loan.monthlyPayment);
  }
  
  List<LoanModel> getLoansForAccount(int accountId) {
    return loans.where((loan) => loan.accountId == accountId).toList();
  }
  
  double getTotalMonthlyPaymentsForAccount(int accountId) {
    final accountLoans = getLoansForAccount(accountId)
        .where((loan) => loan.getAutomaticStatus() != LoanStatus.completed);
    return accountLoans.fold(0.0, (sum, loan) => sum + loan.monthlyPayment);
  }
}
