import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/core/services/isar_service.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/data/models/loan_model.dart';
import 'package:mybudget/data/models/revenue_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataController extends GetxController {
  final RxBool isExporting = false.obs;
  final RxBool isImporting = false.obs;
  final RxString error = ''.obs;

  Future<Map<String, dynamic>> _prepareExportData() async {
    final accountController = Get.find<AccountController>();
    final expenseController = Get.find<ExpenseController>();
    final revenueController = Get.find<RevenueController>();
    final loanController = Get.find<LoanController>();

    return {
      'accounts': accountController.accounts.map((account) => account.toJson()).toList(),
      'expenses': expenseController.expenses.map((expense) => expense.toJson()).toList(),
      'revenues': revenueController.revenues.map((revenue) => revenue.toJson()).toList(),
      'loans': loanController.loans.map((loan) => {
        'id': loan.id,
        'name': loan.name,
        'amount': loan.amount,
        'account_id': loan.accountId,
        'lender_name': loan.lenderName,
        'monthly_payment': loan.monthlyPayment,
        'day_of_month': loan.dayOfMonth,
      }).toList(),
    };
  }

  Future<void> exportUserData(BuildContext context) async {
    try {
      isExporting.value = true;
      error.value = '';

      final data = await _prepareExportData();
      final jsonData = jsonEncode(data);
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mybudget_data.json');
      await file.writeAsString(jsonData);
      
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MyBudget - Données exportées',
        text: 'Sauvegarde de vos données MyBudget',
      );
      
      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Données exportées avec succès')),
        );
      }
    } catch (e) {
      error.value = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'export: $e')),
      );
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> importUserData(BuildContext context, File file) async {
    try {
      isImporting.value = true;
      error.value = '';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importation en cours...')),
      );
      
      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // Get service and controllers
      final isarService = Get.find<IsarService>();
      final accountController = Get.find<AccountController>();
      final expenseController = Get.find<ExpenseController>();
      final revenueController = Get.find<RevenueController>();
      final loanController = Get.find<LoanController>();
      
      // Clear all existing data
      await isarService.clearAllData();
      
      // Import accounts
      if (data['accounts'] != null && data['accounts'] is List) {
        for (final accountData in data['accounts']) {
          try {
            final account = AccountModel.fromJson(accountData);
            await accountController.addAccount(account);
          } catch (e) {
            print('Error importing account: $e');
          }
        }
      }
      
      // Import expenses
      if (data['expenses'] != null && data['expenses'] is List) {
        for (final expenseData in data['expenses']) {
          try {
            final expense = ExpenseModel.fromJson(expenseData);
            await expenseController.addExpense(expense);
          } catch (e) {
            print('Error importing expense: $e');
          }
        }
      }
      
      // Import revenues
      if (data['revenues'] != null && data['revenues'] is List) {
        for (final revenueData in data['revenues']) {
          try {
            final revenue = RevenueModel.fromJson(revenueData);
            await revenueController.addRevenue(revenue);
          } catch (e) {
            print('Error importing revenue: $e');
          }
        }
      }
      
      // Import loans
      if (data['loans'] != null && data['loans'] is List) {
        for (final loanData in data['loans']) {
          try {
            // Create minimal loan object from JSON data
            final loan = LoanModel(
              id: loanData['id'] as int? ?? 0,
              name: loanData['name'] as String? ?? '',
              amount: (loanData['amount'] as num?)?.toDouble() ?? 0.0,
              accountId: loanData['account_id'] as int? ?? 0,
              startDate: DateTime.now(),
              lenderName: loanData['lender_name'] as String? ?? 'Non spécifié',
              monthlyPayment: (loanData['monthly_payment'] as num?)?.toDouble() ?? 0.0,
              dayOfMonth: loanData['day_of_month'] as int? ?? 1,
              endDate: DateTime.now().add(const Duration(days: 365)),
            );
            await loanController.addLoan(loan);
          } catch (e) {
            print('Error importing loan: $e');
          }
        }
      }
      
      // Trigger controllers to refresh data
      await accountController.getAccounts();
      await expenseController.getExpenses();
      await revenueController.getRevenues();
      await loanController.fetchLoans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importation terminée avec succès')),
      );
    } catch (e) {
      error.value = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'importation: $e')),
      );
    } finally {
      isImporting.value = false;
    }
  }
  
  Future<void> deleteAllUserData(BuildContext context) async {
    try {
      error.value = '';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression des données en cours...')),
      );
      
      // Get service and controllers
      final isarService = Get.find<IsarService>();
      final accountController = Get.find<AccountController>();
      final expenseController = Get.find<ExpenseController>();
      final revenueController = Get.find<RevenueController>();
      final loanController = Get.find<LoanController>();
      
      // Clear all data using isar service
      await isarService.clearAllData();
      
      // Refresh controllers
      await accountController.getAccounts();
      await expenseController.getExpenses();
      await revenueController.getRevenues();
      await loanController.fetchLoans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les données ont été supprimées')),
      );
    } catch (e) {
      error.value = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }
}
