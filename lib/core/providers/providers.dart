import 'package:app_updater/app_updater.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/services/category_memory_service.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/services/annual_percentage_rate_service.dart';
import 'package:mybudget/core/services/early_repayment_indemnity_service.dart';
import 'package:mybudget/core/services/loan_payoff_service.dart';
import 'package:mybudget/core/services/loan_schedule_service.dart';
import 'package:mybudget/core/services/loan_service.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
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
Future<ObjectBoxService> objectBoxService(Ref ref) {
  return ObjectBoxService.getInstance();
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
TransferRepository transferRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return TransferRepository(obs.transferBox);
}
