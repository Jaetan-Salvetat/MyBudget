import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/provider/beneficiary_provider.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/provider/loans_provider.dart';
import 'package:mybudget/data/provider/revenues_provider.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';

class AppRestart {
  static void restartApp(BuildContext context) {
    _invalidateAllProviders(context);
    _resetNavigation(context);
  }

  static void _invalidateAllProviders(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    container.invalidate(accountProvider);
    container.invalidate(beneficiaryProvider);
    container.invalidate(categoryOverrideProvider);
    container.invalidate(expenseProvider);
    container.invalidate(revenueProvider);
    container.invalidate(loanProvider);
  }

  static void _resetNavigation(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }
}
