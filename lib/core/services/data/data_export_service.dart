import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/time/clock.dart';

class DataExportService {
  const DataExportService({
    required this.accountRepo,
    required this.beneficiaryRepo,
    required this.categoryOverrideRepo,
    required this.categoryMemoryRepo,
    required this.expenseRepo,
    required this.revenueRepo,
    required this.loanRepo,
    required this.loanEventRepo,
    required this.transferRepo,
    required this.clock,
  });
  final AccountRepository accountRepo;
  final BeneficiaryRepository beneficiaryRepo;
  final CategoryOverrideRepository categoryOverrideRepo;
  final CategoryMemoryRepository categoryMemoryRepo;
  final ExpenseRepository expenseRepo;
  final RevenueRepository revenueRepo;
  final LoanRepository loanRepo;
  final LoanEventRepository loanEventRepo;
  final TransferRepository transferRepo;
  final Clock clock;

  Map<String, dynamic> buildExportData() {
    final now = clock();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return {
      'version': 3,
      'exportDate': now.toIso8601String(),
      'filename': 'mybudget_backup_$dateStr.json',
      'accounts': accountRepo.getAll().map((a) => a.toJson()).toList(),
      'beneficiaries': beneficiaryRepo.getAll().map((b) => b.toJson()).toList(),
      'categoryOverrides': categoryOverrideRepo
          .getAll()
          .values
          .map((override) => override.toJson())
          .toList(),
      'categoryMemory': categoryMemoryRepo
          .getAll()
          .map((entry) => entry.toJson())
          .toList(),
      'expenses': expenseRepo.getAll().map((e) => e.toJson()).toList(),
      'revenues': revenueRepo.getAll().map((r) => r.toJson()).toList(),
      'loans': loanRepo.getAll().map((l) => l.toJson()).toList(),
      'loanEvents': loanEventRepo.getAll().map((e) => e.toJson()).toList(),
      'transfers': transferRepo.getAll().map((t) => t.toJson()).toList(),
    };
  }
}
