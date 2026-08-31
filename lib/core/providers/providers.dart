import 'package:app_updater/app_updater.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/services/category_memory_service.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/legacy_category_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/services/data/legacy_backup_upgrader.dart';
import 'package:mybudget/core/services/data/legacy_category_mapper.dart';
import 'package:mybudget/core/services/data/legacy_category_migration.dart';
import 'package:mybudget/core/services/data/legacy_loan_defaults_migration.dart';
import 'package:mybudget/core/services/annual_percentage_rate_service.dart';
import 'package:mybudget/core/services/early_repayment_indemnity_service.dart';
import 'package:mybudget/core/services/loan_payoff_service.dart';
import 'package:mybudget/core/services/loan_schedule_service.dart';
import 'package:mybudget/core/services/loan_service.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transaction_event_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/ai/api_key_verifier.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/ai/quick_add_engine_health.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_model_runner.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

final appUpdaterProvider = Provider<AppUpdater>(
  (ref) => throw UnimplementedError('AppUpdater must be overridden at startup'),
);

@Riverpod(keepAlive: true)
Future<ObjectBoxService> objectBoxService(Ref ref) async {
  final service = await ObjectBoxService.getInstance();
  final taxonomy = await ref.watch(categoryTaxonomyProvider.future);

  await LegacyCategoryMigration(
    expenses: ExpenseRepository(service.expenseBox),
    legacyCategories: LegacyCategoryRepository(service.legacyCategoryBox),
    mapper: LegacyCategoryMapper(taxonomy),
  ).run();

  await LegacyLoanDefaultsMigration(
    loans: LoanRepository(service.loanBox),
  ).run();

  return service;
}

@Riverpod(keepAlive: true)
Future<CategoryTaxonomyService> categoryTaxonomy(Ref ref) async {
  final taxonomy = CategoryTaxonomyService();
  await taxonomy.load();
  return taxonomy;
}

@Riverpod(keepAlive: true)
Future<QuickAddClassifierService> quickAddClassifier(Ref ref) async {
  final service = QuickAddClassifierService(
    tokenizer: QuickAddTokenizer(),
    modelRunner: QuickAddModelRunner(OnnxRuntime()),
    taxonomy: await ref.watch(categoryTaxonomyProvider.future),
  );
  await service.load();
  return service;
}

@Riverpod(keepAlive: true)
LegacyBackupUpgrader legacyBackupUpgrader(Ref ref) {
  return LegacyBackupUpgrader(
    LegacyCategoryMapper(ref.watch(categoryTaxonomyProvider).requireValue),
  );
}

@Riverpod(keepAlive: true)
ApiKeyService apiKeyService(Ref ref) => ApiKeyService();

@Riverpod(keepAlive: true)
ApiKeyVerifier apiKeyVerifier(Ref ref) {
  return ApiKeyVerifier(
    clientFactory: (provider, model, apiKey) => OpenAiCompatibleChatClient(
      provider: provider,
      model: model,
      apiKey: apiKey,
    ),
  );
}

@Riverpod(keepAlive: true)
QuickAddEngineHealth quickAddEngineHealth(Ref ref) => QuickAddEngineHealth();

@Riverpod(keepAlive: true)
GeminiNanoService geminiNanoService(Ref ref) => const GeminiNanoService();

@Riverpod(keepAlive: true)
Future<GeminiNanoStatus> geminiNanoStatus(Ref ref) {
  return ref.watch(geminiNanoServiceProvider).status();
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return AccountRepository(obs.accountBox);
}

@Riverpod(keepAlive: true)
BeneficiaryRepository beneficiaryRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return BeneficiaryRepository(obs.beneficiaryBox);
}

@Riverpod(keepAlive: true)
CategoryMemoryRepository categoryMemoryRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return CategoryMemoryRepository(obs.categoryMemoryBox);
}

@Riverpod(keepAlive: true)
CategoryMemoryService categoryMemory(Ref ref) {
  return CategoryMemoryService(ref.watch(categoryMemoryRepositoryProvider));
}

@Riverpod(keepAlive: true)
CategoryOverrideRepository categoryOverrideRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return CategoryOverrideRepository(obs.categoryOverrideBox);
}

@Riverpod(keepAlive: true)
ExpenseRepository expenseRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return ExpenseRepository(obs.expenseBox);
}

@Riverpod(keepAlive: true)
LoanRepository loanRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return LoanRepository(obs.loanBox);
}

@Riverpod(keepAlive: true)
LoanEventRepository loanEventRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return LoanEventRepository(obs.loanEventBox);
}

@Riverpod(keepAlive: true)
LoanScheduleService loanScheduleService(Ref ref) {
  return const LoanScheduleService(EarlyRepaymentIndemnityService());
}

@Riverpod(keepAlive: true)
LoanService loanService(Ref ref) {
  return LoanService(
    ref.watch(loanScheduleServiceProvider),
    const AnnualPercentageRateService(),
  );
}

@Riverpod(keepAlive: true)
LoanPayoffService loanPayoffService(Ref ref) {
  return LoanPayoffService(ref.watch(loanScheduleServiceProvider));
}

@Riverpod(keepAlive: true)
RevenueRepository revenueRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return RevenueRepository(obs.revenueBox);
}

@Riverpod(keepAlive: true)
TransactionEventRepository transactionEventRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return TransactionEventRepository(obs.transactionEventBox);
}

@Riverpod(keepAlive: true)
TransferRepository transferRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return TransferRepository(obs.transferBox);
}
