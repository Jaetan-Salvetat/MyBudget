import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/data/model/category_memory_model.dart';
import 'package:mybudget/data/model/category_override_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/loan_event_model.dart';
import 'package:mybudget/data/model/loan_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/model/transfer_model.dart';

class ParsedBeneficiary {
  const ParsedBeneficiary({required this.oldId, required this.model});
  final int oldId;
  final BeneficiaryModel model;
}

class ParsedAccount {
  const ParsedAccount({required this.oldId, required this.model});
  final int oldId;
  final AccountModel model;
}

class ParsedCategoryOverride {
  const ParsedCategoryOverride({required this.model});
  final CategoryOverrideModel model;
}

class ParsedCategoryMemory {
  const ParsedCategoryMemory({required this.model});
  final CategoryMemoryModel model;
}

class ParsedExpense {
  const ParsedExpense({
    required this.oldId,
    required this.model,
    this.oldAccountId,
    this.oldBeneficiaryId,
    this.oldParentId,
  });
  final int oldId;
  final int? oldAccountId;
  final int? oldBeneficiaryId;
  final int? oldParentId;
  final ExpenseModel model;
}

class ParsedRevenue {
  const ParsedRevenue({
    required this.oldId,
    required this.model,
    this.oldAccountId,
    this.oldBeneficiaryId,
    this.oldParentId,
  });
  final int oldId;
  final int? oldAccountId;
  final int? oldBeneficiaryId;
  final int? oldParentId;
  final RevenueModel model;
}

class ParsedLoan {
  const ParsedLoan({
    required this.model,
    required this.oldId,
    this.oldAccountId,
  });
  final int oldId;
  final int? oldAccountId;
  final LoanModel model;
}

class ParsedLoanEvent {
  const ParsedLoanEvent({required this.model, required this.oldLoanId});
  final int oldLoanId;
  final LoanEventModel model;
}

class ParsedTransfer {
  const ParsedTransfer({
    required this.oldId,
    required this.model,
    this.oldFromAccountId,
    this.oldToAccountId,
    this.oldParentId,
  });
  final int oldId;
  final int? oldFromAccountId;
  final int? oldToAccountId;
  final int? oldParentId;
  final TransferModel model;
}

class ImportValidationResult {
  const ImportValidationResult({
    required this.isValid,
    this.beneficiaries = const [],
    this.accounts = const [],
    this.categoryOverrides = const [],
    this.categoryMemory = const [],
    this.expenses = const [],
    this.revenues = const [],
    this.loans = const [],
    this.loanEvents = const [],
    this.transfers = const [],
    this.errors = const [],
  });
  final bool isValid;
  final List<ParsedBeneficiary> beneficiaries;
  final List<ParsedAccount> accounts;
  final List<ParsedCategoryOverride> categoryOverrides;
  final List<ParsedCategoryMemory> categoryMemory;
  final List<ParsedExpense> expenses;
  final List<ParsedRevenue> revenues;
  final List<ParsedLoan> loans;
  final List<ParsedLoanEvent> loanEvents;
  final List<ParsedTransfer> transfers;
  final List<String> errors;

  bool get hasCategoryOverrides => categoryOverrides.isNotEmpty;

  int get totalItems =>
      beneficiaries.length +
      accounts.length +
      categoryOverrides.length +
      expenses.length +
      revenues.length +
      loans.length +
      loanEvents.length +
      transfers.length;
}
