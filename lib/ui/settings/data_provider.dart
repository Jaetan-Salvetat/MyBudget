import 'dart:convert';
import 'dart:io';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/data/data_export_service.dart';
import 'package:mybudget/core/services/data/data_import_service.dart';
import 'package:mybudget/core/services/data/import_report.dart';
import 'package:mybudget/core/services/data/import_validation_result.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_provider.g.dart';

class DataState {
  final bool isExporting;
  final bool isImporting;
  final bool isDeleting;
  final String error;
  final double importProgress;
  final String importStatus;
  final ImportReport? importReport;

  const DataState({
    this.isExporting = false,
    this.isImporting = false,
    this.isDeleting = false,
    this.error = '',
    this.importProgress = 0.0,
    this.importStatus = '',
    this.importReport,
  });

  DataState copyWith({
    bool? isExporting,
    bool? isImporting,
    bool? isDeleting,
    String? error,
    double? importProgress,
    String? importStatus,
    ImportReport? importReport,
  }) {
    return DataState(
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error ?? this.error,
      importProgress: importProgress ?? this.importProgress,
      importStatus: importStatus ?? this.importStatus,
      importReport: importReport ?? this.importReport,
    );
  }
}

@Riverpod(keepAlive: true)
class DataNotifier extends _$DataNotifier {
  @override
  DataState build() => const DataState();

  DataImportService _createImportService() {
    return DataImportService(
      accountRepo: ref.read(accountRepositoryProvider),
      beneficiaryRepo: ref.read(beneficiaryRepositoryProvider),
      categoryOverrideRepo: ref.read(categoryOverrideRepositoryProvider),
      categoryMemoryRepo: ref.read(categoryMemoryRepositoryProvider),
      expenseRepo: ref.read(expenseRepositoryProvider),
      revenueRepo: ref.read(revenueRepositoryProvider),
      loanRepo: ref.read(loanRepositoryProvider),
      transferRepo: ref.read(transferRepositoryProvider),
    );
  }

  DataExportService _createExportService() {
    return DataExportService(
      accountRepo: ref.read(accountRepositoryProvider),
      beneficiaryRepo: ref.read(beneficiaryRepositoryProvider),
      categoryOverrideRepo: ref.read(categoryOverrideRepositoryProvider),
      categoryMemoryRepo: ref.read(categoryMemoryRepositoryProvider),
      expenseRepo: ref.read(expenseRepositoryProvider),
      revenueRepo: ref.read(revenueRepositoryProvider),
      loanRepo: ref.read(loanRepositoryProvider),
      transferRepo: ref.read(transferRepositoryProvider),
    );
  }

  Future<String> exportUserData() async {
    try {
      state = state.copyWith(isExporting: true, error: '');

      final exportService = _createExportService();
      final data = exportService.buildExportData();
      final fileName = data['filename'] as String;

      final jsonData = jsonEncode(data);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonData);

      return file.path;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isExporting: false);
    }
  }

  ImportValidationResult validateImportData(String jsonContent) {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    final importService = _createImportService();
    return importService.validate(data);
  }

  Future<void> importUserData(String jsonContent) async {
    try {
      state = state.copyWith(
        isImporting: true,
        error: '',
        importProgress: 0.0,
        importStatus: 'Validation des données...',
      );

      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final importService = _createImportService();

      final validated = importService.validate(data);

      if (validated.errors.isNotEmpty) {
        state = state.copyWith(
          importStatus: 'Importation avec avertissements...',
        );
      }

      state = state.copyWith(
        importStatus: 'Importation en cours...',
        importProgress: 0.05,
      );

      final report = importService.execute(
        validated,
        onProgress: (progress, status) {
          state = state.copyWith(
            importProgress: 0.05 + (progress * 0.95),
            importStatus: status,
          );
        },
      );

      state = state.copyWith(
        importProgress: 1.0,
        importStatus: 'Importation terminée',
        importReport: report,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isImporting: false);
    }
  }

  Future<void> deleteAllUserData() async {
    try {
      state = state.copyWith(isDeleting: true, error: '');

      await Future.delayed(const Duration(seconds: 1));

      ref.read(beneficiaryRepositoryProvider).deleteAll();
      ref.read(accountRepositoryProvider).deleteAll();
      ref.read(expenseRepositoryProvider).deleteAll();
      ref.read(revenueRepositoryProvider).deleteAll();
      ref.read(loanRepositoryProvider).deleteAll();
      ref.read(transferRepositoryProvider).deleteAll();
      ref.read(categoryOverrideRepositoryProvider).deleteAll();
      ref.read(categoryMemoryRepositoryProvider).deleteAll();

      await PreferencesService.clearAll();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isDeleting: false);
    }
  }
}
