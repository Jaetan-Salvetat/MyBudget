import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:mybudget/data/service/account_balance_data.dart';
import 'package:mybudget/data/service/upcoming_item_data.dart';

class HomeWidgetSyncService {
  static const _monthlySummaryName =
      'fr.jaetan.mybudget.widget.MonthlySummaryWidgetProvider';
  static const _accountBalanceName =
      'fr.jaetan.mybudget.widget.AccountBalanceWidgetProvider';
  static const _upcomingPaymentsName =
      'fr.jaetan.mybudget.widget.UpcomingPaymentsWidgetProvider';

  static Future<void> syncMonthlySummary({
    required double netBalance,
    required double monthlyRevenues,
    required double monthlyExpenses,
    required double totalMonthlyLoanPayments,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData(
        'widget_net_balance',
        netBalance.toStringAsFixed(2),
      ),
      HomeWidget.saveWidgetData(
        'widget_monthly_revenues',
        monthlyRevenues.toStringAsFixed(2),
      ),
      HomeWidget.saveWidgetData(
        'widget_monthly_expenses',
        monthlyExpenses.toStringAsFixed(2),
      ),
      HomeWidget.saveWidgetData(
        'widget_monthly_loan_payments',
        totalMonthlyLoanPayments.toStringAsFixed(2),
      ),
    ]);
    await HomeWidget.updateWidget(qualifiedAndroidName: _monthlySummaryName);
  }

  static Future<void> syncAccountBalances(
    List<AccountBalanceData> accounts,
  ) async {
    final json = jsonEncode(accounts.take(6).map((a) => a.toJson()).toList());
    await HomeWidget.saveWidgetData('widget_accounts_json', json);
    await HomeWidget.updateWidget(qualifiedAndroidName: _accountBalanceName);
  }

  static Future<void> syncUpcomingPayments(List<UpcomingItemData> items) async {
    final json = jsonEncode(items.take(8).map((i) => i.toJson()).toList());
    await HomeWidget.saveWidgetData('widget_upcoming_json', json);
    await HomeWidget.updateWidget(qualifiedAndroidName: _upcomingPaymentsName);
  }
}
