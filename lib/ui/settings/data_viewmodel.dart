import 'package:flutter/material.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataViewModel extends ChangeNotifier {
  final AccountRepository _accountRepository;
  final ExpenseRepository _expenseRepository;
  final RevenueRepository _revenueRepository;
  final LoanRepository _loanRepository;
  final CategoryRepository _categoryRepository;

  final AccountViewModel _accountViewModel;
  final ExpenseViewModel _expenseViewModel;
  final RevenueViewModel _revenueViewModel;
  final LoanViewModel _loanViewModel;

  bool _isExporting = false;
  bool _isImporting = false;
  String _error = '';

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  String get error => _error;

  DataViewModel(
    this._accountRepository,
    this._expenseRepository,
    this._revenueRepository,
    this._loanRepository,
    this._categoryRepository,
    this._accountViewModel,
    this._expenseViewModel,
    this._revenueViewModel,
    this._loanViewModel,
  );

  Future<Map<String, dynamic>> _prepareExportData() async {
    return {
      'accounts':
          _accountViewModel.accounts
              .map((account) => account.toJson())
              .toList(),
      'expenses':
          _expenseViewModel.expenses
              .map((expense) => expense.toJson())
              .toList(),
      'revenues':
          _revenueViewModel.revenues
              .map((revenue) => revenue.toJson())
              .toList(),
      'loans':
          _loanViewModel.loans
              .map(
                (loan) => {
                  'id': loan.id,
                  'name': loan.name,
                  'amount': loan.amount,
                  'account_id': loan.accountId,
                  'lender_name': loan.lenderName,
                  'monthly_payment': loan.monthlyPayment,
                  'day_of_month': loan.dayOfMonth,
                  'start_date': loan.startDate.toIso8601String(),
                  'end_date': loan.endDate.toIso8601String(),
                },
              )
              .toList(),
    };
  }

  Future<void> exportUserData(BuildContext context) async {
    try {
      _isExporting = true;
      _error = '';
      notifyListeners();

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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Données exportées avec succès')),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export: $e')));
      }
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> importUserData(BuildContext context, File file) async {
    try {
      _isImporting = true;
      _error = '';
      notifyListeners();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Importation en cours...')));

      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      _accountRepository.deleteAll();
      _expenseRepository.deleteAll();
      _revenueRepository.deleteAll();
      _loanRepository.deleteAll();
      _categoryRepository.deleteAll();

      if (data['accounts'] != null && data['accounts'] is List) {
        for (final accountData in data['accounts']) {
          try {
            final account = AccountModel.fromJson(accountData);

            _accountRepository.add(account);
          } catch (e) {
            debugPrint('Error importing account: $e');
          }
        }
      }

      if (data['expenses'] != null && data['expenses'] is List) {
        for (final expenseData in data['expenses']) {
          try {
            final expense = ExpenseModel.fromJson(expenseData);
            _expenseRepository.add(expense);
          } catch (e) {
            debugPrint('Error importing expense: $e');
          }
        }
      }

      if (data['revenues'] != null && data['revenues'] is List) {
        for (final revenueData in data['revenues']) {
          try {
            final revenue = RevenueModel.fromJson(revenueData);
            _revenueRepository.add(revenue);
          } catch (e) {
            debugPrint('Error importing revenue: $e');
          }
        }
      }

      if (data['loans'] != null && data['loans'] is List) {
        for (final loanData in data['loans']) {
          try {
            final loan = LoanModel(
              id: loanData['id'] as int? ?? 0,
              name: loanData['name'] as String? ?? '',
              amount: (loanData['amount'] as num?)?.toDouble() ?? 0.0,
              accountId: loanData['account_id'] as int? ?? 0,
              startDate:
                  DateTime.tryParse(loanData['start_date'] ?? '') ??
                  DateTime.now(),
              lenderName: loanData['lender_name'] as String? ?? 'Non spécifié',
              monthlyPayment:
                  (loanData['monthly_payment'] as num?)?.toDouble() ?? 0.0,
              dayOfMonth: loanData['day_of_month'] as int? ?? 1,
              endDate:
                  DateTime.tryParse(loanData['end_date'] ?? '') ??
                  DateTime.now().add(const Duration(days: 365)),
            );
            _loanRepository.add(loan);
          } catch (e) {
            debugPrint('Error importing loan: $e');
          }
        }
      }

      await _accountViewModel.getAccounts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importation terminée avec succès')),
      );
    } catch (e) {
      _error = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'importation: $e')),
      );
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> deleteAllUserData(BuildContext context) async {
    try {
      _error = '';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression des données en cours...')),
      );

      _accountRepository.deleteAll();
      _expenseRepository.deleteAll();
      _revenueRepository.deleteAll();
      _loanRepository.deleteAll();
      _categoryRepository.deleteAll();

      await _accountViewModel.getAccounts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les données ont été supprimées')),
      );
    } catch (e) {
      _error = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }
}
