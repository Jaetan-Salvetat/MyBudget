import 'package:mybudget/data/repository/account_repository.dart';
import 'package:mybudget/data/repository/beneficiary_repository.dart';
import 'package:mybudget/data/repository/category_memory_repository.dart';
import 'package:mybudget/data/repository/category_override_repository.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/legacy_category_repository.dart';
import 'package:mybudget/data/repository/loan_event_repository.dart';
import 'package:mybudget/data/repository/loan_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/data/repository/transaction_event_repository.dart';
import 'package:mybudget/data/repository/transfer_repository.dart';

class UserDataEraser {
  const UserDataEraser({
    required this.accounts,
    required this.beneficiaries,
    required this.categoryMemories,
    required this.categoryOverrides,
    required this.expenses,
    required this.legacyCategories,
    required this.loanEvents,
    required this.loans,
    required this.revenues,
    required this.transactionEvents,
    required this.transfers,
  });

  final AccountRepository accounts;
  final BeneficiaryRepository beneficiaries;
  final CategoryMemoryRepository categoryMemories;
  final CategoryOverrideRepository categoryOverrides;
  final ExpenseRepository expenses;
  final LegacyCategoryRepository legacyCategories;
  final LoanEventRepository loanEvents;
  final LoanRepository loans;
  final RevenueRepository revenues;
  final TransactionEventRepository transactionEvents;
  final TransferRepository transfers;

  void eraseAll() {
    accounts.deleteAll();
    beneficiaries.deleteAll();
    categoryMemories.deleteAll();
    categoryOverrides.deleteAll();
    expenses.deleteAll();
    legacyCategories.deleteAll();
    loanEvents.deleteAll();
    loans.deleteAll();
    revenues.deleteAll();
    transactionEvents.deleteAll();
    transfers.deleteAll();
  }
}
