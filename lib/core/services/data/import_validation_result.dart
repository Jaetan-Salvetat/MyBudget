import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/category_memory_model.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/transfer_model.dart';

class ParsedBeneficiary {
  final int oldId;
  final BeneficiaryModel model;
  const ParsedBeneficiary({required this.oldId, required this.model});
}

class ParsedAccount {
  final int oldId;
  final AccountModel model;
  const ParsedAccount({required this.oldId, required this.model});
}

class ParsedCategoryOverride {
  final CategoryOverrideModel model;
  const ParsedCategoryOverride({required this.model});
}

class ParsedCategoryMemory {
  final CategoryMemoryModel model;
  const ParsedCategoryMemory({required this.model});
}

class ParsedExpense {
  final int oldId;
  final int? oldAccountId;
  final int? oldBeneficiaryId;
  final int? oldParentId;
  final ExpenseModel model;
  const ParsedExpense({
    required this.oldId,
    required this.model,
    this.oldAccountId,
    this.oldBeneficiaryId,
    this.oldParentId,
  });
}

class ParsedRevenue {
  final int oldId;
  final int? oldAccountId;
  final int? oldBeneficiaryId;
  final int? oldParentId;
  final RevenueModel model;
  const ParsedRevenue({
    required this.oldId,
    required this.model,
    this.oldAccountId,
    this.oldBeneficiaryId,
    this.oldParentId,
  });
}

class ParsedLoan {
  final int? oldAccountId;
  final LoanModel model;
  const ParsedLoan({required this.model, this.oldAccountId});
}

class ParsedTransfer {
  final int oldId;
  final int? oldFromAccountId;
  final int? oldToAccountId;
  final int? oldParentId;
  final TransferModel model;
  const ParsedTransfer({
    required this.oldId,
    required this.model,
    this.oldFromAccountId,
    this.oldToAccountId,
    this.oldParentId,
  });
}

class ImportValidationResult {
  final bool isValid;
  final List<ParsedBeneficiary> beneficiaries;
  final List<ParsedAccount> accounts;
  final List<ParsedCategoryOverride> categoryOverrides;
  final List<ParsedCategoryMemory> categoryMemory;
  final List<ParsedExpense> expenses;
  final List<ParsedRevenue> revenues;
  final List<ParsedLoan> loans;
  final List<ParsedTransfer> transfers;
  final List<String> errors;

  const ImportValidationResult({
    required this.isValid,
    this.beneficiaries = const [],
    this.accounts = const [],
    this.categoryOverrides = const [],
    this.categoryMemory = const [],
    this.expenses = const [],
    this.revenues = const [],
    this.loans = const [],
    this.transfers = const [],
    this.errors = const [],
  });

  bool get hasCategoryOverrides => categoryOverrides.isNotEmpty;

  int get totalItems =>
      beneficiaries.length +
      accounts.length +
      categoryOverrides.length +
      expenses.length +
      revenues.length +
      loans.length +
      transfers.length;
}
