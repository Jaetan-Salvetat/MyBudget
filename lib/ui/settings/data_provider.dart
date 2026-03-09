import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/utils/app_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'data_provider.g.dart';

class DataState {
  final bool isExporting;
  final bool isImporting;
  final bool isDeleting;
  final String error;
  final double importProgress;
  final String importStatus;

  const DataState({
    this.isExporting = false,
    this.isImporting = false,
    this.isDeleting = false,
    this.error = '',
    this.importProgress = 0.0,
    this.importStatus = '',
  });

  DataState copyWith({
    bool? isExporting,
    bool? isImporting,
    bool? isDeleting,
    String? error,
    double? importProgress,
    String? importStatus,
  }) {
    return DataState(
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error ?? this.error,
      importProgress: importProgress ?? this.importProgress,
      importStatus: importStatus ?? this.importStatus,
    );
  }
}

@Riverpod(keepAlive: true)
class DataNotifier extends _$DataNotifier {
  @override
  DataState build() => const DataState();

  Future<Map<String, dynamic>> _prepareExportData() async {
    final accountRepo = ref.read(accountRepositoryProvider);
    final beneficiaryRepo = ref.read(beneficiaryRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final expenseRepo = ref.read(expenseRepositoryProvider);
    final revenueRepo = ref.read(revenueRepositoryProvider);
    final loanRepo = ref.read(loanRepositoryProvider);

    final expenses = expenseRepo.getAll();
    final revenues = revenueRepo.getAll();
    final loanModels = loanRepo.getAll();

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
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'revenues': revenues.map((r) => r.toJson()).toList(),
      'loans': loanModels.map((loan) => {
        'id': loan.id,
        'name': loan.name,
        'amount': loan.amount,
        'account_id': loan.accountId,
        'lender_name': loan.lenderName,
        'day_of_month': loan.dayOfMonth,
        'start_date': loan.startDate.toIso8601String(),
        'end_date': loan.endDate.toIso8601String(),
        'interest_rate': loan.interestRate,
        'duration': loan.duration,
        'repayment_type_id': loan.repaymentTypeId,
        'deferred_months': loan.deferredMonths,
        'insurance_type_id': loan.insuranceTypeId,
        'insurance_value': loan.insuranceValue,
        'insurance_calculation_mode_id': loan.insuranceCalculationModeId,
        'notes': loan.notes,
      }).toList(),
    };
  }

  Future<void> exportUserData(BuildContext context) async {
    try {
      state = state.copyWith(isExporting: true, error: '');

      final data = await _prepareExportData();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'mybudget_backup_$dateStr.json';

      final jsonData = jsonEncode(data);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonData);

      final result = await SharePlus.instance.share(
        ShareParams(
          text: 'Sauvegarde de vos données MyBudget',
          subject: 'MyBudget - Données exportées',
          files: [XFile(file.path)],
        ),
      );

      if (result.status == ShareResultStatus.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Données exportées avec succès')),
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export: $e')),
        );
      }
    } finally {
      state = state.copyWith(isExporting: false);
    }
  }

  Future<void> importUserData(BuildContext context, File file) async {
    try {
      state = state.copyWith(
        isImporting: true,
        error: '',
        importProgress: 0.0,
        importStatus: 'Lecture du fichier...',
      );

      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      debugPrint('Début import. Taille JSON: ${jsonData.length} caractères');

      state = state.copyWith(
        importStatus: 'Suppression des données existantes...',
        importProgress: 0.05,
      );

      // Suppression dans le bon ordre
      final beneficiaryRepo = ref.read(beneficiaryRepositoryProvider);
      final accountRepo = ref.read(accountRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final revenueRepo = ref.read(revenueRepositoryProvider);
      final loanRepo = ref.read(loanRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);

      beneficiaryRepo.deleteAll();
      accountRepo.deleteAll();
      expenseRepo.deleteAll();
      revenueRepo.deleteAll();
      loanRepo.deleteAll();
      categoryRepo.deleteAll();

      final Map<int, int> accountIdMap = {};
      final Map<int, int> beneficiaryIdMap = {};
      final Map<int, int> categoryIdMap = {};

      // ---- Bénéficiaires ----
      if (data['beneficiaries'] is List) {
        final list = data['beneficiaries'] as List;
        state = state.copyWith(importStatus: 'Importation des bénéficiaires...');
        for (final item in list) {
          try {
            final oldId = int.tryParse(item['id'].toString()) ?? 0;
            item['id'] = 0;
            final model = BeneficiaryModel.fromJson(Map<String, dynamic>.from(item));
            final newId = beneficiaryRepo.add(model);
            beneficiaryIdMap[oldId] = newId;
          } catch (e) {
            debugPrint('ERREUR bénéficiaire: $e');
          }
        }
      }
      state = state.copyWith(importProgress: 0.1);

      // ---- Comptes ----
      if (data['accounts'] is List) {
        final list = data['accounts'] as List;
        state = state.copyWith(importStatus: 'Importation des comptes...');
        for (var i = 0; i < list.length; i++) {
          try {
            final item = list[i];
            final oldId = int.tryParse(item['id'].toString()) ?? 0;
            item['id'] = 0;
            final model = AccountModel.fromJson(item);
            final newId = accountRepo.add(model);
            accountIdMap[oldId] = newId;
            state = state.copyWith(importProgress: 0.1 + (0.15 * ((i + 1) / list.length)));
          } catch (e) {
            debugPrint('ERREUR compte: $e');
          }
        }
      }

      // ---- Catégories ----
      if (data['categories'] is List) {
        final list = data['categories'] as List;
        state = state.copyWith(importStatus: 'Importation des catégories...');
        for (var i = 0; i < list.length; i++) {
          try {
            final item = list[i];
            final oldId = int.tryParse(item['id'].toString()) ?? 0;
            item['id'] = 0;
            final model = CategoryModel.fromJson(Map<String, dynamic>.from(item));
            final newId = categoryRepo.add(model);
            categoryIdMap[oldId] = newId;
            state = state.copyWith(importProgress: 0.25 + (0.15 * ((i + 1) / list.length)));
          } catch (e) {
            debugPrint('ERREUR catégorie: $e');
          }
        }
        await PreferencesService.setCategoriesCreated();
      }

      // ---- Dépenses ----
      if (data['expenses'] is List) {
        final list = data['expenses'] as List;
        state = state.copyWith(importStatus: 'Importation des dépenses...');
        int success = 0;
        for (var i = 0; i < list.length; i++) {
          try {
            final item = list[i];
            final oldAccountId = int.tryParse(item['accountId'].toString());
            final oldCategoryId = int.tryParse(item['categoryId'].toString());

            // Ignorer si le compte ou la catégorie est introuvable dans le mapping
            if (oldAccountId != null && !accountIdMap.containsKey(oldAccountId)) {
              debugPrint('Dépense ignorée : accountId $oldAccountId introuvable');
              continue;
            }
            if (oldCategoryId != null && !categoryIdMap.containsKey(oldCategoryId)) {
              debugPrint('Dépense ignorée : categoryId $oldCategoryId introuvable');
              continue;
            }

            if (oldAccountId != null) item['accountId'] = accountIdMap[oldAccountId];
            if (oldCategoryId != null) item['categoryId'] = categoryIdMap[oldCategoryId];

            item['id'] = 0;

            final oldBeneficiaryId = item['beneficiaryId'] != null
                ? int.tryParse(item['beneficiaryId'].toString())
                : null;
            if (oldBeneficiaryId != null) {
              item['beneficiaryId'] = beneficiaryIdMap[oldBeneficiaryId]?.toString();
            }

            final model = ExpenseModel.fromJson(item);
            expenseRepo.add(model);
            success++;
            state = state.copyWith(importProgress: 0.4 + (0.2 * ((i + 1) / list.length)));
          } catch (e) {
            debugPrint('ERREUR dépense: $e');
          }
        }
        debugPrint('Dépenses: $success / ${list.length}');
      }

      // ---- Revenus ----
      if (data['revenues'] is List) {
        final list = data['revenues'] as List;
        state = state.copyWith(importStatus: 'Importation des revenus...');
        int success = 0;
        for (var i = 0; i < list.length; i++) {
          try {
            final item = list[i];
            final oldAccountId = int.tryParse(item['accountId'].toString());

            if (oldAccountId != null && !accountIdMap.containsKey(oldAccountId)) {
              debugPrint('Revenu ignoré : accountId $oldAccountId introuvable');
              continue;
            }
            if (oldAccountId != null) item['accountId'] = accountIdMap[oldAccountId];

            item['id'] = 0;

            final oldBeneficiaryId = item['beneficiaryId'] != null
                ? int.tryParse(item['beneficiaryId'].toString())
                : null;
            if (oldBeneficiaryId != null) {
              item['beneficiaryId'] = beneficiaryIdMap[oldBeneficiaryId]?.toString();
            }

            final model = RevenueModel.fromJson(item);
            revenueRepo.add(model);
            success++;
            state = state.copyWith(importProgress: 0.6 + (0.15 * ((i + 1) / list.length)));
          } catch (e) {
            debugPrint('ERREUR revenu: $e');
          }
        }
        debugPrint('Revenus: $success / ${list.length}');
      }

      // ---- Prêts ----
      if (data['loans'] is List) {
        final list = data['loans'] as List;
        state = state.copyWith(importStatus: 'Importation des emprunts...');
        int success = 0;
        for (var i = 0; i < list.length; i++) {
          try {
            final item = list[i];
            final oldAccountId = int.tryParse(item['account_id'].toString());

            if (oldAccountId != null && !accountIdMap.containsKey(oldAccountId)) {
              debugPrint('Prêt ignoré : accountId $oldAccountId introuvable');
              continue;
            }
            if (oldAccountId != null) item['account_id'] = accountIdMap[oldAccountId];

            final loan = LoanModel(
              id: 0,
              name: item['name'] as String? ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
              accountId: item['account_id'] as int? ?? 0,
              startDate: DateTime.tryParse(item['start_date'] ?? '') ?? DateTime.now(),
              lenderName: item['lender_name'] as String? ?? 'Non spécifié',
              dayOfMonth: item['day_of_month'] as int? ?? 1,
              endDate: DateTime.tryParse(item['end_date'] ?? '') ??
                  DateTime.now().add(const Duration(days: 365)),
              interestRate: (item['interest_rate'] as num?)?.toDouble() ?? 0.0,
              duration: item['duration'] as int? ?? 0,
              repaymentTypeId: item['repayment_type_id'] as String? ?? 'amortizable',
              deferredMonths: item['deferred_months'] as int? ?? 0,
              insuranceTypeId: item['insurance_type_id'] as String? ?? 'none',
              insuranceValue: (item['insurance_value'] as num?)?.toDouble() ?? 0.0,
              insuranceCalculationModeId:
                  item['insurance_calculation_mode_id'] as String? ?? 'initialCapital',
              notes: item['notes'] as String?,
            );
            loanRepo.add(loan);
            success++;
            state = state.copyWith(importProgress: 0.75 + (0.2 * ((i + 1) / list.length)));
          } catch (e) {
            debugPrint('ERREUR prêt: $e');
          }
        }
        debugPrint('Prêts: $success / ${list.length}');
      }

      state = state.copyWith(importStatus: 'Finalisation...', importProgress: 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importation terminée avec succès')),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'importation: $e')),
        );
      }
    } finally {
      state = state.copyWith(isImporting: false);
    }
  }

  Future<void> deleteAllUserData(BuildContext context) async {
    try {
      state = state.copyWith(isDeleting: true, error: '');

      await Future.delayed(const Duration(seconds: 1));

      ref.read(beneficiaryRepositoryProvider).deleteAll();
      ref.read(accountRepositoryProvider).deleteAll();
      ref.read(expenseRepositoryProvider).deleteAll();
      ref.read(revenueRepositoryProvider).deleteAll();
      ref.read(loanRepositoryProvider).deleteAll();
      ref.read(categoryRepositoryProvider).deleteAll();

      if (context.mounted) {
        await PreferencesService.clearAll();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    } finally {
      state = state.copyWith(isDeleting: false);
    }
  }

  /// Restart de l'app après import/suppression (géré par AppUtils)
  void restartApp(BuildContext context) {
    AppUtils.restartApp(context);
  }
}
