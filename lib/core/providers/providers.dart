import 'package:app_updater/app_updater.dart';
import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/enums/local_model_status.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/litert_engine_service.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
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
Future<LitertEngineService?> litertEngine(Ref ref) async {
  final status = LocalModelStatus.fromString(
    PreferencesService.getLocalModelStatus(),
  );
  if (status != LocalModelStatus.ready) return null;

  final modelPath = PreferencesService.getLocalModelPath();
  if (modelPath == null) return null;

  try {
    return await LitertEngineService.getInstance(
      modelPath,
      LiteLmBackend.gpu,
    );
  } on Object {
    try {
      return await LitertEngineService.getInstance(
        modelPath,
        LiteLmBackend.cpu,
      );
    } catch (_) {
      await PreferencesService.setLocalModelStatus('none');
      await PreferencesService.setLocalModelPath(null);
      return null;
    }
  }
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
CategoryRepository categoryRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return CategoryRepository(obs.categoryBox);
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
RevenueRepository revenueRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return RevenueRepository(obs.revenueBox);
}

@Riverpod(keepAlive: true)
TransferRepository transferRepository(Ref ref) {
  final obs = ref.watch(objectBoxServiceProvider).requireValue;
  return TransferRepository(obs.transferBox);
}
