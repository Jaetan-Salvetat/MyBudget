import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Future<ObjectBoxService> objectBoxService(Ref ref) {
  return ObjectBoxService.getInstance();
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
