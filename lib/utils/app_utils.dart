import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';

class AppUtils {
  static void restartApp(BuildContext context) {
    _invalidateAllProviders(context);
    _resetNavigation(context);
  }

  static void _invalidateAllProviders(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    container.invalidate(accountProvider);
    container.invalidate(beneficiaryProvider);
    container.invalidate(categoryProvider);
    container.invalidate(expenseProvider);
    container.invalidate(revenueProvider);
    container.invalidate(loanProvider);
  }

  static void _resetNavigation(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }
}
