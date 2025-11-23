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
  double _importProgress = 0.0;
  String _importStatus = '';

  bool _isDeleting = false;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  bool get isDeleting => _isDeleting;
  String get error => _error;
  double get importProgress => _importProgress;
  String get importStatus => _importStatus;

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
      _importProgress = 0.0;
      _importStatus = 'Lecture du fichier...';
      notifyListeners();

      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      debugPrint(
        'Début de l\'importation. Taille du JSON: ${jsonData.length} caractères',
      );

      _importStatus = 'Suppression des données existantes...';
      _importProgress = 0.1;
      notifyListeners();

      _accountRepository.deleteAll();
      _expenseRepository.deleteAll();
      _revenueRepository.deleteAll();
      _loanRepository.deleteAll();
      _categoryRepository.deleteAll();

      // Map pour stocker la correspondance entre anciens IDs et nouveaux IDs des comptes
      final Map<int, int> accountIdMap = {};

      // 1. Importer les comptes
      if (data['accounts'] != null && data['accounts'] is List) {
        final accountsList = data['accounts'] as List;
        final totalAccounts = accountsList.length;
        debugPrint('Importation de $totalAccounts comptes...');

        _importStatus = 'Importation des comptes...';
        notifyListeners();

        for (var i = 0; i < totalAccounts; i++) {
          try {
            final accountData = accountsList[i];
            // Gestion robuste de l'ID (peut être String ou int)
            final oldId = int.tryParse(accountData['id'].toString()) ?? 0;
            final accountName = accountData['name'] as String? ?? 'Inconnu';

            // On force l'ID à 0 pour qu'ObjectBox en génère un nouveau
            accountData['id'] = 0;
            final account = AccountModel.fromJson(accountData);

            final newId = _accountRepository.add(account);
            accountIdMap[oldId] = newId;
            debugPrint(
              'Compte importé: "$accountName" (Ancien ID: $oldId -> Nouvel ID: $newId)',
            );

            _importProgress = 0.1 + (0.2 * ((i + 1) / totalAccounts));
            notifyListeners();
          } catch (e) {
            debugPrint('ERREUR importation compte à l\'index $i: $e');
          }
        }
        debugPrint('Mapping des IDs de comptes: $accountIdMap');
      } else {
        debugPrint('Aucun compte trouvé dans le fichier d\'import.');
      }

      // 2. Importer les dépenses
      if (data['expenses'] != null && data['expenses'] is List) {
        final expensesList = data['expenses'] as List;
        final totalExpenses = expensesList.length;
        debugPrint('Importation de $totalExpenses dépenses...');

        _importStatus = 'Importation des dépenses...';
        notifyListeners();

        int successCount = 0;
        for (var i = 0; i < totalExpenses; i++) {
          try {
            final expenseData = expensesList[i];

            // Mettre à jour l'accountId avec le nouvel ID
            // Gestion robuste de l'ID (peut être String ou int)
            final oldAccountId = int.tryParse(
              expenseData['accountId'].toString(),
            );

            if (oldAccountId != null) {
              if (accountIdMap.containsKey(oldAccountId)) {
                expenseData['accountId'] = accountIdMap[oldAccountId];
              } else {
                debugPrint(
                  'ATTENTION: Dépense ignorée ou orpheline - AccountID $oldAccountId introuvable dans le mapping.',
                );
                // On continue quand même, peut-être avec un accountId par défaut ou null ?
                // Pour l'instant, on laisse tel quel, mais l'intégrité référentielle risque d'être brisée.
              }
            }

            // Reset ID
            expenseData['id'] = 0;

            final expense = ExpenseModel.fromJson(expenseData);
            _expenseRepository.add(expense);
            successCount++;

            _importProgress = 0.3 + (0.3 * ((i + 1) / totalExpenses));
            notifyListeners();
          } catch (e) {
            debugPrint('ERREUR importation dépense à l\'index $i: $e');
          }
        }
        debugPrint('Dépenses importées: $successCount / $totalExpenses');
      } else {
        debugPrint('Aucune dépense trouvée dans le fichier d\'import.');
      }

      // 3. Importer les revenus
      if (data['revenues'] != null && data['revenues'] is List) {
        final revenuesList = data['revenues'] as List;
        final totalRevenues = revenuesList.length;
        debugPrint('Importation de $totalRevenues revenus...');

        _importStatus = 'Importation des revenus...';
        notifyListeners();

        int successCount = 0;
        for (var i = 0; i < totalRevenues; i++) {
          try {
            final revenueData = revenuesList[i];

            // Mettre à jour l'accountId
            // Gestion robuste de l'ID (peut être String ou int)
            final oldAccountId = int.tryParse(
              revenueData['accountId'].toString(),
            );

            if (oldAccountId != null &&
                accountIdMap.containsKey(oldAccountId)) {
              revenueData['accountId'] = accountIdMap[oldAccountId];
            } else if (oldAccountId != null) {
              debugPrint(
                'ATTENTION: Revenu orphelin - AccountID $oldAccountId introuvable.',
              );
            }

            // Reset ID
            revenueData['id'] = 0;

            final revenue = RevenueModel.fromJson(revenueData);
            _revenueRepository.add(revenue);
            successCount++;

            _importProgress = 0.6 + (0.2 * ((i + 1) / totalRevenues));
            notifyListeners();
          } catch (e) {
            debugPrint('ERREUR importation revenu à l\'index $i: $e');
          }
        }
        debugPrint('Revenus importés: $successCount / $totalRevenues');
      }

      // 4. Importer les prêts
      if (data['loans'] != null && data['loans'] is List) {
        final loansList = data['loans'] as List;
        final totalLoans = loansList.length;
        debugPrint('Importation de $totalLoans prêts...');

        _importStatus = 'Importation des emprunts...';
        notifyListeners();

        int successCount = 0;
        for (var i = 0; i < totalLoans; i++) {
          try {
            final loanData = loansList[i];

            // Mettre à jour l'accountId
            // Gestion robuste de l'ID (peut être String ou int)
            final oldAccountId = int.tryParse(
              loanData['account_id'].toString(),
            );

            if (oldAccountId != null &&
                accountIdMap.containsKey(oldAccountId)) {
              loanData['account_id'] = accountIdMap[oldAccountId];
            }

            final loan = LoanModel(
              id: 0, // Reset ID
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
            successCount++;

            _importProgress = 0.8 + (0.2 * ((i + 1) / totalLoans));
            notifyListeners();
          } catch (e) {
            debugPrint('ERREUR importation prêt à l\'index $i: $e');
          }
        }
        debugPrint('Prêts importés: $successCount / $totalLoans');
      }

      _importStatus = 'Finalisation...';
      _importProgress = 1.0;
      notifyListeners();

      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Petit délai pour voir la fin

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importation terminée avec succès')),
        );
      }
    } catch (e) {
      _error = e.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'importation: $e')),
        );
      }
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> deleteAllUserData(BuildContext context) async {
    try {
      _isDeleting = true;
      _error = '';
      notifyListeners();

      // Simulate a small delay to show loading state
      await Future.delayed(const Duration(seconds: 1));

      _accountRepository.deleteAll();
      _expenseRepository.deleteAll();
      _revenueRepository.deleteAll();
      _loanRepository.deleteAll();
      _categoryRepository.deleteAll();

      // Success is handled by UI dialog
    } catch (e) {
      _error = e.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
