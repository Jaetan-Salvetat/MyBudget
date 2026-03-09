import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/data/import_report.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';

// ─── Wrappers pour stocker les anciens IDs étrangers ───

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

// ─── Résultat de validation ───

class ImportValidationResult {
  final bool isValid;
  final List<ParsedBeneficiary> beneficiaries;
  final List<ParsedAccount> accounts;
  final List<ParsedCategory> categories;
  final List<ParsedExpense> expenses;
  final List<ParsedRevenue> revenues;
  final List<ParsedLoan> loans;
  final List<String> errors;

  const ImportValidationResult({
    required this.isValid,
    this.beneficiaries = const [],
    this.accounts = const [],
    this.categories = const [],
    this.expenses = const [],
    this.revenues = const [],
    this.loans = const [],
    this.errors = const [],
  });

  bool get hasCategories => categories.isNotEmpty;

  int get totalItems =>
      beneficiaries.length +
      accounts.length +
      categories.length +
      expenses.length +
      revenues.length +
      loans.length;
}

// ─── Service d'import (pur, sans Riverpod ni BuildContext) ───

class DataImportService {
  final AccountRepository accountRepo;
  final BeneficiaryRepository beneficiaryRepo;
  final CategoryRepository categoryRepo;
  final ExpenseRepository expenseRepo;
  final RevenueRepository revenueRepo;
  final LoanRepository loanRepo;

  const DataImportService({
    required this.accountRepo,
    required this.beneficiaryRepo,
    required this.categoryRepo,
    required this.expenseRepo,
    required this.revenueRepo,
    required this.loanRepo,
  });

  /// Phase 1 : Parse et valide le JSON sans toucher la BDD.
  ImportValidationResult validate(Map<String, dynamic> data) {
    final errors = <String>[];
    final beneficiaries = <ParsedBeneficiary>[];
    final accounts = <ParsedAccount>[];
    final categories = <ParsedCategory>[];
    final expenses = <ParsedExpense>[];
    final revenues = <ParsedRevenue>[];
    final loans = <ParsedLoan>[];

    // Bénéficiaires
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

    // Comptes
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

    // Catégories
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

    // Dépenses
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

    // Revenus
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

    // Emprunts (supporte camelCase et snake_case via LoanModel.fromJson)
    if (data['loans'] is List) {
      for (final item in data['loans'] as List) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          // Supporte les deux formats : accountId (nouveau) et account_id (legacy)
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

    return ImportValidationResult(
      isValid: true, // Le JSON est parseable même si certains items ont échoué
      beneficiaries: beneficiaries,
      accounts: accounts,
      categories: categories,
      expenses: expenses,
      revenues: revenues,
      loans: loans,
      errors: errors,
    );
  }

  /// Phase 2 : Supprime les données existantes et insère les nouvelles
  /// avec remapping des IDs. Appelé UNIQUEMENT après validate().
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

    // Suppression des données existantes
    onProgress?.call(0.0, 'Suppression des données existantes...');
    beneficiaryRepo.deleteAll();
    accountRepo.deleteAll();
    expenseRepo.deleteAll();
    revenueRepo.deleteAll();
    loanRepo.deleteAll();
    categoryRepo.deleteAll();

    final Map<int, int> beneficiaryIdMap = {};
    final Map<int, int> accountIdMap = {};
    final Map<int, int> categoryIdMap = {};

    // ── Bénéficiaires ──
    reportProgress('Importation des bénéficiaires...');
    final beneficiaryReport = _importBeneficiaries(
      validated.beneficiaries,
      beneficiaryIdMap,
      () {
        processedItems++;
        reportProgress('Importation des bénéficiaires...');
      },
    );

    // ── Comptes ──
    reportProgress('Importation des comptes...');
    final accountReport = _importAccounts(
      validated.accounts,
      accountIdMap,
      () {
        processedItems++;
        reportProgress('Importation des comptes...');
      },
    );

    // ── Catégories ──
    reportProgress('Importation des catégories...');
    final categoryReport = _importCategories(
      validated.categories,
      categoryIdMap,
      () {
        processedItems++;
        reportProgress('Importation des catégories...');
      },
    );

    // ── Dépenses ──
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

    // ── Revenus ──
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

    // ── Emprunts ──
    reportProgress('Importation des emprunts...');
    final loanReport = _importLoans(
      validated.loans,
      accountIdMap,
      () {
        processedItems++;
        reportProgress('Importation des emprunts...');
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
    );
  }

  // ─── Méthodes d'import par entité ───

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
        // Vérifier que le compte et la catégorie existent dans le mapping
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

        // Remapper les IDs
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
}
