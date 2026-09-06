import 'package:mybudget/core/time/clock.dart';
import 'package:mybudget/core/utils/json_fields.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/data/model/category_memory_model.dart';
import 'package:mybudget/data/model/category_override_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/loan_event_model.dart';
import 'package:mybudget/data/model/loan_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/model/transfer_model.dart';
import 'package:mybudget/data/repository/account_repository.dart';
import 'package:mybudget/data/repository/beneficiary_repository.dart';
import 'package:mybudget/data/repository/category_memory_repository.dart';
import 'package:mybudget/data/repository/category_override_repository.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/loan_event_repository.dart';
import 'package:mybudget/data/repository/loan_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/data/repository/transfer_repository.dart';
import 'package:mybudget/data/service/data/import_entity_report.dart';
import 'package:mybudget/data/service/data/import_report.dart';
import 'package:mybudget/data/service/data/import_validation_result.dart';
import 'package:mybudget/data/service/data/user_data_eraser.dart';
import 'package:mybudget/data/service/loan_service.dart';

class DataImportService {
  const DataImportService({
    required this.accountRepo,
    required this.beneficiaryRepo,
    required this.categoryOverrideRepo,
    required this.categoryMemoryRepo,
    required this.expenseRepo,
    required this.revenueRepo,
    required this.loanRepo,
    required this.loanEventRepo,
    required this.loanService,
    required this.transferRepo,
    required this.eraser,
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
  final LoanService loanService;
  final TransferRepository transferRepo;
  final UserDataEraser eraser;
  final Clock clock;

  ImportValidationResult validate(Map<String, dynamic> data) {
    final DateTime now = clock();
    final errors = <String>[];

    List<P> parseSection<P>(
      String key,
      String label,
      P Function(Map<String, dynamic> json) parse,
    ) {
      final section = data[key];
      if (section is! List) return <P>[];

      final parsed = <P>[];
      for (final item in section) {
        try {
          parsed.add(parse(Map<String, dynamic>.from(item as Map)));
        } catch (error) {
          errors.add('$label : $error');
        }
      }
      return parsed;
    }

    return ImportValidationResult(
      isValid: true,
      beneficiaries: parseSection('beneficiaries', 'Bénéficiaire invalide', (
        json,
      ) {
        final oldId = json.readInt('id', 0);
        json['id'] = '0';
        return ParsedBeneficiary(
          oldId: oldId,
          model: BeneficiaryModel.fromJson(json),
        );
      }),
      accounts: parseSection('accounts', 'Compte invalide', (json) {
        final oldId = json.readInt('id', 0);
        json['id'] = '0';
        return ParsedAccount(oldId: oldId, model: AccountModel.fromJson(json));
      }),
      categoryOverrides: parseSection(
        'categoryOverrides',
        'Personnalisation de catégorie invalide',
        (json) {
          json['id'] = '0';
          return ParsedCategoryOverride(
            model: CategoryOverrideModel.fromJson(json),
          );
        },
      ),
      categoryMemory: parseSection(
        'categoryMemory',
        'Mémoire de catégorie invalide',
        (json) => ParsedCategoryMemory(
          model: CategoryMemoryModel.fromJson(json, now: now),
        ),
      ),
      expenses: parseSection('expenses', 'Dépense invalide', (json) {
        final oldId = json.readInt('id', 0);
        final oldAccountId = json.readOptionalInt('accountId');
        final oldBeneficiaryId = json.readOptionalInt('beneficiaryId');
        final oldParentId = json.readOptionalInt('parentId');
        json['id'] = '0';
        json['parentId'] = null;
        return ParsedExpense(
          oldId: oldId,
          model: ExpenseModel.fromJson(json, now: now),
          oldAccountId: oldAccountId,
          oldBeneficiaryId: oldBeneficiaryId,
          oldParentId: oldParentId,
        );
      }),
      revenues: parseSection('revenues', 'Revenu invalide', (json) {
        final oldId = json.readInt('id', 0);
        final oldAccountId = json.readOptionalInt('accountId');
        final oldBeneficiaryId = json.readOptionalInt('beneficiaryId');
        final oldParentId = json.readOptionalInt('parentId');
        json['id'] = '0';
        json['parentId'] = null;
        return ParsedRevenue(
          oldId: oldId,
          model: RevenueModel.fromJson(json, now: now),
          oldAccountId: oldAccountId,
          oldBeneficiaryId: oldBeneficiaryId,
          oldParentId: oldParentId,
        );
      }),
      loans: parseSection('loans', 'Emprunt invalide', (json) {
        final oldId = json.readInt('id', 0);
        final oldAccountId =
            json.readOptionalInt('accountId') ??
            json.readOptionalInt('account_id');
        json['id'] = '0';
        return ParsedLoan(
          model: LoanModel.fromJson(json, now: now),
          oldId: oldId,
          oldAccountId: oldAccountId,
        );
      }),
      loanEvents: parseSection('loanEvents', 'Événement d\'emprunt invalide', (
        json,
      ) {
        final oldLoanId =
            json.readOptionalInt('loanId') ??
            json.readOptionalInt('loan_id') ??
            0;
        json['id'] = '0';
        return ParsedLoanEvent(
          model: LoanEventModel.fromJson(json, now: now),
          oldLoanId: oldLoanId,
        );
      }),
      transfers: parseSection('transfers', 'Virement invalide', (json) {
        final oldId = json.readInt('id', 0);
        final oldFromAccountId = json.readOptionalInt('fromAccountId');
        final oldToAccountId = json.readOptionalInt('toAccountId');
        final oldParentId = json.readOptionalInt('parentId');
        json['id'] = '0';
        json['parentId'] = null;
        return ParsedTransfer(
          oldId: oldId,
          model: TransferModel.fromJson(json, now: now),
          oldFromAccountId: oldFromAccountId,
          oldToAccountId: oldToAccountId,
          oldParentId: oldParentId,
        );
      }),
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
    eraser.eraseAll();

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
    final accountReport = _importAccounts(validated.accounts, accountIdMap, () {
      processedItems++;
      reportProgress('Importation des comptes...');
    });

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
    final Map<int, int> loanIdMap = {};
    final loanReport = _importLoans(
      validated.loans,
      accountIdMap,
      loanIdMap,
      () {
        processedItems++;
        reportProgress('Importation des emprunts...');
      },
    );

    reportProgress('Importation des remboursements anticipés...');
    final loanEventReport = _importLoanEvents(
      validated.loanEvents,
      loanIdMap,
      () {
        processedItems++;
        reportProgress('Importation des remboursements anticipés...');
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
      loanEvents: loanEventReport,
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
    Map<int, int> loanIdMap,
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

        model.endDate = loanService.endDateOf(model);
        loanIdMap[item.oldId] = loanRepo.add(model);
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

  ImportEntityReport _importLoanEvents(
    List<ParsedLoanEvent> items,
    Map<int, int> loanIdMap,
    void Function() onItemProcessed,
  ) {
    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final item in items) {
      try {
        final newLoanId = loanIdMap[item.oldLoanId];
        if (newLoanId == null) {
          skipped++;
          onItemProcessed();
          continue;
        }

        loanEventRepo.add(item.model.copyWith(loanId: newLoanId));
        imported++;
      } catch (e) {
        errors.add('${item.model.type.label} : $e');
      }
      onItemProcessed();
    }

    return ImportEntityReport(
      entityName: 'Remboursements anticipés',
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
