import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/data/import_entity_report.dart';
import 'package:mybudget/core/services/data/import_report.dart';
import 'package:mybudget/core/services/data/import_validation_result.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/category_memory_model.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/transfer_model.dart';

class DataImportService {
  final AccountRepository accountRepo;
  final BeneficiaryRepository beneficiaryRepo;
  final CategoryOverrideRepository categoryOverrideRepo;
  final CategoryMemoryRepository categoryMemoryRepo;
  final ExpenseRepository expenseRepo;
  final RevenueRepository revenueRepo;
  final LoanRepository loanRepo;
  final TransferRepository transferRepo;

  const DataImportService({
    required this.accountRepo,
    required this.beneficiaryRepo,
    required this.categoryOverrideRepo,
    required this.categoryMemoryRepo,
    required this.expenseRepo,
    required this.revenueRepo,
    required this.loanRepo,
    required this.transferRepo,
  });

  ImportValidationResult validate(Map<String, dynamic> data) {
    final errors = <String>[];
    final beneficiaries = <ParsedBeneficiary>[];
    final accounts = <ParsedAccount>[];
    final categoryOverrides = <ParsedCategoryOverride>[];
    final categoryMemory = <ParsedCategoryMemory>[];
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

    if (data['categoryOverrides'] is List) {
      for (final item in data['categoryOverrides'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          json['id'] = '0';
          categoryOverrides.add(ParsedCategoryOverride(
            model: CategoryOverrideModel.fromJson(json),
          ));
        } catch (e) {
          errors.add('Personnalisation de catégorie invalide : $e');
        }
      }
    }

    if (data['categoryMemory'] is List) {
      for (final item in data['categoryMemory'] as List) {
        try {
          categoryMemory.add(ParsedCategoryMemory(
            model: CategoryMemoryModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ));
        } catch (e) {
          errors.add('Mémoire de catégorie invalide : $e');
        }
      }
    }

    if (data['expenses'] is List) {
      for (final item in data['expenses'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final oldId = int.tryParse(json['id']?.toString() ?? '') ?? 0;
          final oldAccountId =
              int.tryParse(json['accountId']?.toString() ?? '');
          final oldBeneficiaryId =
              int.tryParse(json['beneficiaryId']?.toString() ?? '');
          final oldParentId =
              int.tryParse(json['parentId']?.toString() ?? '');
          json['id'] = '0';
          json['parentId'] = null;
          expenses.add(ParsedExpense(
            oldId: oldId,
            model: ExpenseModel.fromJson(json),
            oldAccountId: oldAccountId,
            oldBeneficiaryId: oldBeneficiaryId,
            oldParentId: oldParentId,
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
          final oldId = int.tryParse(json['id']?.toString() ?? '') ?? 0;
          final oldAccountId =
              int.tryParse(json['accountId']?.toString() ?? '');
          final oldBeneficiaryId =
              int.tryParse(json['beneficiaryId']?.toString() ?? '');
          final oldParentId =
              int.tryParse(json['parentId']?.toString() ?? '');
          json['id'] = '0';
          json['parentId'] = null;
          revenues.add(ParsedRevenue(
            oldId: oldId,
            model: RevenueModel.fromJson(json),
            oldAccountId: oldAccountId,
            oldBeneficiaryId: oldBeneficiaryId,
            oldParentId: oldParentId,
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
          final oldId = int.tryParse(json['id']?.toString() ?? '') ?? 0;
          final oldFromAccountId =
              int.tryParse(json['fromAccountId']?.toString() ?? '');
          final oldToAccountId =
              int.tryParse(json['toAccountId']?.toString() ?? '');
          final oldParentId =
              int.tryParse(json['parentId']?.toString() ?? '');
          json['id'] = '0';
          json['parentId'] = null;
          transfers.add(ParsedTransfer(
            oldId: oldId,
            model: TransferModel.fromJson(json),
            oldFromAccountId: oldFromAccountId,
            oldToAccountId: oldToAccountId,
            oldParentId: oldParentId,
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
      categoryOverrides: categoryOverrides,
      categoryMemory: categoryMemory,
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
    categoryOverrideRepo.deleteAll();
    categoryMemoryRepo.deleteAll();

    final Map<int, int> beneficiaryIdMap = {};
    final Map<int, int> accountIdMap = {};

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
    final categoryReport = _importCategoryOverrides(
      validated.categoryOverrides,
      () {
        processedItems++;
        reportProgress('Importation des catégories...');
      },
    );

    for (final entry in validated.categoryMemory) {
      categoryMemoryRepo.put(entry.model);
    }

    reportProgress('Importation des dépenses...');
    final expenseReport = _importExpenses(
      validated.expenses,
      accountIdMap,
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

  ImportEntityReport _importCategoryOverrides(
    List<ParsedCategoryOverride> items,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    final errors = <String>[];
    for (final item in items) {
      try {
        categoryOverrideRepo.save(item.model);
        imported++;
      } catch (e) {
        errors.add('${item.model.slug} : $e');
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
    Map<int, int> beneficiaryIdMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    int skipped = 0;
    final errors = <String>[];
    final Map<int, int> expenseIdMap = {};
    final List<({int newId, int oldParentId})> pendingParentIds = [];

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

        final newId = expenseRepo.add(model);
        expenseIdMap[item.oldId] = newId;
        if (item.oldParentId != null) {
          pendingParentIds.add((newId: newId, oldParentId: item.oldParentId!));
        }
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }

    for (final pending in pendingParentIds) {
      final newParentId = expenseIdMap[pending.oldParentId];
      if (newParentId != null) {
        final model = expenseRepo.get(pending.newId);
        if (model != null) {
          expenseRepo.update(model.copyWith(parentId: newParentId));
        }
      }
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
    final Map<int, int> revenueIdMap = {};
    final List<({int newId, int oldParentId})> pendingParentIds = [];

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

        final newId = revenueRepo.add(model);
        revenueIdMap[item.oldId] = newId;
        if (item.oldParentId != null) {
          pendingParentIds.add((newId: newId, oldParentId: item.oldParentId!));
        }
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }

    for (final pending in pendingParentIds) {
      final newParentId = revenueIdMap[pending.oldParentId];
      if (newParentId != null) {
        final model = revenueRepo.get(pending.newId);
        if (model != null) {
          revenueRepo.update(model.copyWith(parentId: newParentId));
        }
      }
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
    final Map<int, int> transferIdMap = {};
    final List<({int newId, int oldParentId})> pendingParentIds = [];

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

        final newId = transferRepo.add(model);
        transferIdMap[item.oldId] = newId;
        if (item.oldParentId != null) {
          pendingParentIds.add((newId: newId, oldParentId: item.oldParentId!));
        }
        imported++;
      } catch (e) {
        errors.add('${item.model.name} : $e');
      }
      onItemProcessed();
    }

    for (final pending in pendingParentIds) {
      final newParentId = transferIdMap[pending.oldParentId];
      if (newParentId != null) {
        final model = transferRepo.get(pending.newId);
        if (model != null) {
          transferRepo.update(model.copyWith(parentId: newParentId));
        }
      }
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
