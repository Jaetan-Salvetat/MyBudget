import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/data/import_report.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/category_model.dart';
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

class ParsedCategory {
  final int oldId;
  final CategoryModel model;
  const ParsedCategory({required this.oldId, required this.model});
}

class ParsedExpense {
  final int? oldAccountId;
  final int? oldCategoryId;
  final int? oldBeneficiaryId;
  final ExpenseModel model;
  const ParsedExpense({
    required this.model,
    this.oldAccountId,
    this.oldCategoryId,
    this.oldBeneficiaryId,
  });
}

class ParsedRevenue {
  final int? oldAccountId;
  final int? oldBeneficiaryId;
  final RevenueModel model;
  const ParsedRevenue({
    required this.model,
    this.oldAccountId,
    this.oldBeneficiaryId,
  });
}

class ParsedLoan {
  final int? oldAccountId;
  final LoanModel model;
  const ParsedLoan({required this.model, this.oldAccountId});
}

class ParsedTransfer {
  final int? oldFromAccountId;
  final int? oldToAccountId;
  final TransferModel model;
  const ParsedTransfer({
    required this.model,
    this.oldFromAccountId,
    this.oldToAccountId,
  });
}

class ImportValidationResult {
  final bool isValid;
  final List<ParsedBeneficiary> beneficiaries;
  final List<ParsedAccount> accounts;
  final List<ParsedCategory> categories;
  final List<ParsedExpense> expenses;
  final List<ParsedRevenue> revenues;
  final List<ParsedLoan> loans;
  final List<ParsedTransfer> transfers;
  final List<String> errors;

  const ImportValidationResult({
    required this.isValid,
    this.beneficiaries = const [],
    this.accounts = const [],
    this.categories = const [],
    this.expenses = const [],
    this.revenues = const [],
    this.loans = const [],
    this.transfers = const [],
    this.errors = const [],
  });

  bool get hasCategories => categories.isNotEmpty;

  int get totalItems =>
      beneficiaries.length +
      accounts.length +
      categories.length +
      expenses.length +
      revenues.length +
      loans.length +
      transfers.length;
}

class DataImportService {
  final AccountRepository accountRepo;
  final BeneficiaryRepository beneficiaryRepo;
  final CategoryRepository categoryRepo;
  final ExpenseRepository expenseRepo;
  final RevenueRepository revenueRepo;
  final LoanRepository loanRepo;
  final TransferRepository transferRepo;

  const DataImportService({
    required this.accountRepo,
    required this.beneficiaryRepo,
    required this.categoryRepo,
    required this.expenseRepo,
    required this.revenueRepo,
    required this.loanRepo,
    required this.transferRepo,
  });

  ImportValidationResult validate(Map<String, dynamic> data) {
    final errors = <String>[];
    final beneficiaries = <ParsedBeneficiary>[];
    final accounts = <ParsedAccount>[];
    final categories = <ParsedCategory>[];
    final expenses = <ParsedExpense>[];
    final revenues = <ParsedRevenue>[];
    final loans = <ParsedLoan>[];
    final transfers = <ParsedTransfer>[];

    if (data['beneficiaries'] is List) {
      for (final item in data['beneficiaries'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final oldId = int.tryParse(json['id'].toString()) ?? 0;
          json['id'] = '0';
          beneficiaries.add(ParsedBeneficiary(
            oldId: oldId,
            model: BeneficiaryModel.fromJson(json),
          ));
        } catch (e) {
          errors.add('Bénéficiaire invalide : $e');
        }
      }
    }

    if (data['accounts'] is List) {
      for (final item in data['accounts'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final oldId = int.tryParse(json['id'].toString()) ?? 0;
          json['id'] = '0';
          accounts.add(ParsedAccount(
            oldId: oldId,
            model: AccountModel.fromJson(json),
          ));
        } catch (e) {
          errors.add('Compte invalide : $e');
        }
      }
    }

    if (data['categories'] is List) {
      for (final item in data['categories'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final oldId = int.tryParse(json['id'].toString()) ?? 0;
          json['id'] = '0';
          categories.add(ParsedCategory(
            oldId: oldId,
            model: CategoryModel.fromJson(json),
          ));
        } catch (e) {
          errors.add('Catégorie invalide : $e');
        }
      }
    }

    if (data['expenses'] is List) {
      for (final item in data['expenses'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final oldAccountId =
              int.tryParse(json['accountId']?.toString() ?? '');
          final oldCategoryId =
              int.tryParse(json['categoryId']?.toString() ?? '');
          final oldBeneficiaryId =
              int.tryParse(json['beneficiaryId']?.toString() ?? '');
          json['id'] = '0';
          expenses.add(ParsedExpense(
            model: ExpenseModel.fromJson(json),
            oldAccountId: oldAccountId,
            oldCategoryId: oldCategoryId,
            oldBeneficiaryId: oldBeneficiaryId,
          ));
        } catch (e) {
          errors.add('Dépense invalide : $e');
        }
      }
    }

    if (data['revenues'] is List) {
      for (final item in data['revenues'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final oldAccountId =
              int.tryParse(json['accountId']?.toString() ?? '');
          final oldBeneficiaryId =
              int.tryParse(json['beneficiaryId']?.toString() ?? '');
          json['id'] = '0';
          revenues.add(ParsedRevenue(
            model: RevenueModel.fromJson(json),
            oldAccountId: oldAccountId,
            oldBeneficiaryId: oldBeneficiaryId,
          ));
        } catch (e) {
          errors.add('Revenu invalide : $e');
        }
      }
    }

    if (data['loans'] is List) {
      for (final item in data['loans'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final oldAccountId = int.tryParse(
            (json['accountId'] ?? json['account_id'] ?? '').toString(),
          );
          json['id'] = '0';
          loans.add(ParsedLoan(
            model: LoanModel.fromJson(json),
            oldAccountId: oldAccountId,
          ));
        } catch (e) {
          errors.add('Emprunt invalide : $e');
        }
      }
    }

    if (data['transfers'] is List) {
      for (final item in data['transfers'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final oldFromAccountId =
              int.tryParse(json['fromAccountId']?.toString() ?? '');
          final oldToAccountId =
              int.tryParse(json['toAccountId']?.toString() ?? '');
          json['id'] = '0';
          transfers.add(ParsedTransfer(
            model: TransferModel.fromJson(json),
            oldFromAccountId: oldFromAccountId,
            oldToAccountId: oldToAccountId,
          ));
        } catch (e) {
          errors.add('Virement invalide : $e');
        }
      }
    }

    return ImportValidationResult(
      isValid: true,
      beneficiaries: beneficiaries,
      accounts: accounts,
      categories: categories,
      expenses: expenses,
      revenues: revenues,
      loans: loans,
      transfers: transfers,
      errors: errors,
    );
  }

  ImportReport execute(
    ImportValidationResult validated, {
    void Function(double progress, String status)? onProgress,
  }) {
    final totalItems = validated.totalItems;
    var processedItems = 0;

    void reportProgress(String status) {
      if (onProgress != null && totalItems > 0) {
        onProgress(processedItems / totalItems, status);
      }
    }

    onProgress?.call(0.0, 'Suppression des données existantes...');
    beneficiaryRepo.deleteAll();
    accountRepo.deleteAll();
    expenseRepo.deleteAll();
    revenueRepo.deleteAll();
    loanRepo.deleteAll();
    transferRepo.deleteAll();
    categoryRepo.deleteAll();

    final Map<int, int> beneficiaryIdMap = {};
    final Map<int, int> accountIdMap = {};
    final Map<int, int> categoryIdMap = {};

    reportProgress('Importation des bénéficiaires...');
    final beneficiaryReport = _importBeneficiaries(
      validated.beneficiaries,
      beneficiaryIdMap,
      () {
        processedItems++;
        reportProgress('Importation des bénéficiaires...');
      },
    );

    reportProgress('Importation des comptes...');
    final accountReport = _importAccounts(
      validated.accounts,
      accountIdMap,
      () {
        processedItems++;
        reportProgress('Importation des comptes...');
      },
    );

    reportProgress('Importation des catégories...');
    final categoryReport = _importCategories(
      validated.categories,
      categoryIdMap,
      () {
        processedItems++;
        reportProgress('Importation des catégories...');
      },
    );

    reportProgress('Importation des dépenses...');
    final expenseReport = _importExpenses(
      validated.expenses,
      accountIdMap,
      categoryIdMap,
      beneficiaryIdMap,
      () {
        processedItems++;
        reportProgress('Importation des dépenses...');
      },
    );

    reportProgress('Importation des revenus...');
    final revenueReport = _importRevenues(
      validated.revenues,
      accountIdMap,
      beneficiaryIdMap,
      () {
        processedItems++;
        reportProgress('Importation des revenus...');
      },
    );

    reportProgress('Importation des emprunts...');
    final loanReport = _importLoans(
      validated.loans,
      accountIdMap,
      () {
        processedItems++;
        reportProgress('Importation des emprunts...');
      },
    );

    reportProgress('Importation des virements...');
    final transferReport = _importTransfers(
      validated.transfers,
      accountIdMap,
      () {
        processedItems++;
        reportProgress('Importation des virements...');
      },
    );

    onProgress?.call(1.0, 'Importation terminée');

    return ImportReport(
      beneficiaries: beneficiaryReport,
      accounts: accountReport,
      categories: categoryReport,
      expenses: expenseReport,
      revenues: revenueReport,
      loans: loanReport,
      transfers: transferReport,
    );
  }

  ImportEntityReport _importBeneficiaries(
    List<ParsedBeneficiary> items,
    Map<int, int> idMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    final errors = <String>[];
    for (final item in items) {
      try {
        final newId = beneficiaryRepo.add(item.model);
        idMap[item.oldId] = newId;
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }
    return ImportEntityReport(
      entityName: 'Bénéficiaires',
      total: items.length,
      imported: imported,
      errors: errors,
    );
  }

  ImportEntityReport _importAccounts(
    List<ParsedAccount> items,
    Map<int, int> idMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    final errors = <String>[];
    for (final item in items) {
      try {
        final newId = accountRepo.add(item.model);
        idMap[item.oldId] = newId;
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }
    return ImportEntityReport(
      entityName: 'Comptes',
      total: items.length,
      imported: imported,
      errors: errors,
    );
  }

  ImportEntityReport _importCategories(
    List<ParsedCategory> items,
    Map<int, int> idMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    final errors = <String>[];
    for (final item in items) {
      try {
        final newId = categoryRepo.add(item.model);
        idMap[item.oldId] = newId;
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }
    return ImportEntityReport(
      entityName: 'Catégories',
      total: items.length,
      imported: imported,
      errors: errors,
    );
  }

  ImportEntityReport _importExpenses(
    List<ParsedExpense> items,
    Map<int, int> accountIdMap,
    Map<int, int> categoryIdMap,
    Map<int, int> beneficiaryIdMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final item in items) {
      try {
        if (item.oldAccountId != null &&
            !accountIdMap.containsKey(item.oldAccountId)) {
          skipped++;
          onItemProcessed();
          continue;
        }
        if (item.oldCategoryId != null &&
            !categoryIdMap.containsKey(item.oldCategoryId)) {
          skipped++;
          onItemProcessed();
          continue;
        }

        final model = item.model;
        if (item.oldAccountId != null) {
          model.accountId = accountIdMap[item.oldAccountId]!;
        }
        if (item.oldCategoryId != null) {
          model.categoryId = categoryIdMap[item.oldCategoryId]!;
        }
        if (item.oldBeneficiaryId != null) {
          model.beneficiaryId = beneficiaryIdMap[item.oldBeneficiaryId];
        }

        expenseRepo.add(model);
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }

    return ImportEntityReport(
      entityName: 'Dépenses',
      total: items.length,
      imported: imported,
      skipped: skipped,
      errors: errors,
    );
  }

  ImportEntityReport _importRevenues(
    List<ParsedRevenue> items,
    Map<int, int> accountIdMap,
    Map<int, int> beneficiaryIdMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final item in items) {
      try {
        if (item.oldAccountId != null &&
            !accountIdMap.containsKey(item.oldAccountId)) {
          skipped++;
          onItemProcessed();
          continue;
        }

        final model = item.model;
        if (item.oldAccountId != null) {
          model.accountId = accountIdMap[item.oldAccountId]!;
        }
        if (item.oldBeneficiaryId != null) {
          model.beneficiaryId = beneficiaryIdMap[item.oldBeneficiaryId];
        }

        revenueRepo.add(model);
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }

    return ImportEntityReport(
      entityName: 'Revenus',
      total: items.length,
      imported: imported,
      skipped: skipped,
      errors: errors,
    );
  }

  ImportEntityReport _importLoans(
    List<ParsedLoan> items,
    Map<int, int> accountIdMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final item in items) {
      try {
        if (item.oldAccountId != null &&
            !accountIdMap.containsKey(item.oldAccountId)) {
          skipped++;
          onItemProcessed();
          continue;
        }

        final model = item.model;
        if (item.oldAccountId != null) {
          model.accountId = accountIdMap[item.oldAccountId]!;
        }

        loanRepo.add(model);
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }

    return ImportEntityReport(
      entityName: 'Emprunts',
      total: items.length,
      imported: imported,
      skipped: skipped,
      errors: errors,
    );
  }

  ImportEntityReport _importTransfers(
    List<ParsedTransfer> items,
    Map<int, int> accountIdMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final item in items) {
      try {
        if (item.oldFromAccountId != null &&
            !accountIdMap.containsKey(item.oldFromAccountId)) {
          skipped++;
          onItemProcessed();
          continue;
        }
        if (item.oldToAccountId != null &&
            !accountIdMap.containsKey(item.oldToAccountId)) {
          skipped++;
          onItemProcessed();
          continue;
        }

        final model = item.model;
        if (item.oldFromAccountId != null) {
          model.fromAccountId = accountIdMap[item.oldFromAccountId]!;
        }
        if (item.oldToAccountId != null) {
          model.toAccountId = accountIdMap[item.oldToAccountId]!;
        }

        transferRepo.add(model);
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }

    return ImportEntityReport(
      entityName: 'Virements',
      total: items.length,
      imported: imported,
      skipped: skipped,
      errors: errors,
    );
  }
}
