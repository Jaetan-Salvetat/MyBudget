import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/time/clock.dart';
import 'package:mybudget/data/provider/retry_policy.dart';
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
import 'package:mybudget/data/service/ai/ai_chat_client.dart';
import 'package:mybudget/data/service/ai/api_key_service.dart';
import 'package:mybudget/data/service/ai/api_key_verifier.dart';
import 'package:mybudget/data/service/ai/gemini_nano_service.dart';
import 'package:mybudget/data/service/annual_percentage_rate_service.dart';
import 'package:mybudget/data/service/category_memory_service.dart';
import 'package:mybudget/data/service/data/legacy_backup_upgrader.dart';
import 'package:mybudget/data/service/data/legacy_category_mapper.dart';
import 'package:mybudget/data/service/data/legacy_category_migration.dart';
import 'package:mybudget/data/service/data/legacy_loan_defaults_migration.dart';
import 'package:mybudget/data/service/data/user_data_eraser.dart';
import 'package:mybudget/data/service/early_repayment_indemnity_service.dart';
import 'package:mybudget/data/service/loan_payoff_service.dart';
import 'package:mybudget/data/service/loan_schedule_service.dart';
import 'package:mybudget/data/service/loan_service.dart';
import 'package:mybudget/data/service/objectbox_service.dart';
import 'package:mybudget/data/service/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/data/service/quick_add/quick_add_classifier_service.dart';
import 'package:mybudget/data/service/quick_add/quick_add_model_runner.dart';
import 'package:mybudget/data/service/quick_add/quick_add_tokenizer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

final clockProvider = Provider<Clock>((ref) => systemNow);

final dataWipeFeedbackDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

final buildFlavorProvider = Provider<BuildFlavor>((ref) => BuildFlavor.current);

final appVersionProvider = Provider<String>(
  (ref) =>
      throw UnimplementedError('App version must be overridden at startup'),
);

final appBuildNumberProvider = Provider<String>(
  (ref) =>
      throw UnimplementedError('Build number must be overridden at startup'),
);

final appBuildCodeProvider = Provider<int?>(
  (ref) => int.tryParse(ref.watch(appBuildNumberProvider)),
);

@Riverpod(keepAlive: true)
Future<ObjectBoxService> objectBoxService(Ref ref) async {
  final service = await ObjectBoxService.getInstance();
  final taxonomy = await ref.watch(categoryTaxonomyProvider.future);

  await LegacyCategoryMigration(
    expenses: ExpenseRepository(service.store),
    legacyCategories: LegacyCategoryRepository(service.store),
    mapper: LegacyCategoryMapper(taxonomy),
  ).run();

  await LegacyLoanDefaultsMigration(
    loans: LoanRepository(service.store),
  ).run();

  return service;
}

@Riverpod(keepAlive: true, retry: failFast)
Future<CategoryTaxonomyService> categoryTaxonomy(Ref ref) async {
  final taxonomy = CategoryTaxonomyService();
  await taxonomy.load();
  return taxonomy;
}

@Riverpod(keepAlive: true, retry: failFast)
Future<QuickAddClassifierService> quickAddClassifier(Ref ref) async {
  final service = QuickAddClassifierService(
    tokenizer: QuickAddTokenizer(),
    modelRunner: QuickAddModelRunner(OnnxRuntime()),
    taxonomy: await ref.watch(categoryTaxonomyProvider.future),
    clock: ref.watch(clockProvider),
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
GeminiNanoService geminiNanoService(Ref ref) => const GeminiNanoService();

@Riverpod(keepAlive: true)
Future<GeminiNanoStatus> geminiNanoStatus(Ref ref) {
  return ref
      .watch(geminiNanoServiceProvider)
      .status(GeminiNanoChannel.fallback, GeminiNanoPreference.scan);
}

@Riverpod(keepAlive: true)
Future<String?> geminiNanoModelName(Ref ref) async {
  final status = await ref.watch(geminiNanoStatusProvider.future);
  if (!status.isReady) return null;

  return ref
      .watch(geminiNanoServiceProvider)
      .modelName(GeminiNanoChannel.fallback, GeminiNanoPreference.scan);
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return AccountRepository(obs.store);
}

@Riverpod(keepAlive: true)
BeneficiaryRepository beneficiaryRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return BeneficiaryRepository(obs.store);
}

@Riverpod(keepAlive: true)
CategoryMemoryRepository categoryMemoryRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return CategoryMemoryRepository(obs.store);
}

@Riverpod(keepAlive: true)
CategoryMemoryService categoryMemory(Ref ref) {
  return CategoryMemoryService(
    ref.watch(categoryMemoryRepositoryProvider),
    ref.watch(clockProvider),
  );
}

@Riverpod(keepAlive: true)
CategoryOverrideRepository categoryOverrideRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return CategoryOverrideRepository(obs.store);
}

@Riverpod(keepAlive: true)
ExpenseRepository expenseRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return ExpenseRepository(obs.store);
}

@Riverpod(keepAlive: true)
LegacyCategoryRepository legacyCategoryRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return LegacyCategoryRepository(obs.store);
}

@Riverpod(keepAlive: true)
UserDataEraser userDataEraser(Ref ref) {
  return UserDataEraser(
    accounts: ref.watch(accountRepositoryProvider),
    beneficiaries: ref.watch(beneficiaryRepositoryProvider),
    categoryMemories: ref.watch(categoryMemoryRepositoryProvider),
    categoryOverrides: ref.watch(categoryOverrideRepositoryProvider),
    expenses: ref.watch(expenseRepositoryProvider),
    legacyCategories: ref.watch(legacyCategoryRepositoryProvider),
    loanEvents: ref.watch(loanEventRepositoryProvider),
    loans: ref.watch(loanRepositoryProvider),
    revenues: ref.watch(revenueRepositoryProvider),
    transactionEvents: ref.watch(transactionEventRepositoryProvider),
    transfers: ref.watch(transferRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
LoanRepository loanRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return LoanRepository(obs.store);
}

@Riverpod(keepAlive: true)
LoanEventRepository loanEventRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return LoanEventRepository(obs.store);
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
  return RevenueRepository(obs.store);
}

@Riverpod(keepAlive: true)
TransactionEventRepository transactionEventRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return TransactionEventRepository(obs.store);
}

@Riverpod(keepAlive: true)
TransferRepository transferRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return TransferRepository(obs.store);
}
