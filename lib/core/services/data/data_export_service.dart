import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';

class DataExportService {
  final AccountRepository accountRepo;
  final BeneficiaryRepository beneficiaryRepo;
  final CategoryRepository categoryRepo;
  final ExpenseRepository expenseRepo;
  final RevenueRepository revenueRepo;
  final LoanRepository loanRepo;

  const DataExportService({
    required this.accountRepo,
    required this.beneficiaryRepo,
    required this.categoryRepo,
    required this.expenseRepo,
    required this.revenueRepo,
    required this.loanRepo,
  });

  /// Construit la map JSON d'export. Pas d'I/O fichier.
  Map<String, dynamic> buildExportData() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return {
      'version': 1,
      'exportDate': now.toIso8601String(),
      'filename': 'mybudget_backup_$dateStr.json',
      'accounts': accountRepo.getAll().map((a) => a.toJson()).toList(),
      'beneficiaries': beneficiaryRepo.getAll().map((b) => b.toJson()).toList(),
      'categories': categoryRepo.getAll().map((c) => c.toJson()).toList(),
      'expenses': expenseRepo.getAll().map((e) => e.toJson()).toList(),
      'revenues': revenueRepo.getAll().map((r) => r.toJson()).toList(),
      'loans': loanRepo.getAll().map((l) => l.toJson()).toList(),
    };
  }
}
