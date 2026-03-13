import 'dart:convert';

import 'package:home_widget/home_widget.dart';

class AccountBalanceData {
  final int id;
  final String name;
  final String bank;
  final double balance;

  const AccountBalanceData({
    required this.id,
    required this.name,
    required this.bank,
    required this.balance,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bank': bank,
    'balance': balance.toStringAsFixed(2),
  };
}

class UpcomingItemData {
  final String name;
  final double amount;
  final int day;
  final String type;
  final String? categoryIcon;

  const UpcomingItemData({
    required this.name,
    required this.amount,
    required this.day,
    required this.type,
    this.categoryIcon,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount.toStringAsFixed(2),
    'day': day,
    'type': type,
    if (categoryIcon != null) 'icon': categoryIcon,
  };
}

class HomeWidgetSyncService {
  static const _qualifiedNames = [
    'fr.jaetan.mybudget.widget.MonthlySummaryWidgetProvider',
    'fr.jaetan.mybudget.widget.AccountBalanceWidgetProvider',
    'fr.jaetan.mybudget.widget.UpcomingPaymentsWidgetProvider',
  ];

  static Future<void> syncMonthlySummary({
    required double netBalance,
    required double monthlyRevenues,
    required double monthlyExpenses,
    required double totalMonthlyLoanPayments,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData('widget_net_balance', netBalance.toStringAsFixed(2)),
      HomeWidget.saveWidgetData('widget_monthly_revenues', monthlyRevenues.toStringAsFixed(2)),
      HomeWidget.saveWidgetData('widget_monthly_expenses', monthlyExpenses.toStringAsFixed(2)),
      HomeWidget.saveWidgetData('widget_monthly_loan_payments', totalMonthlyLoanPayments.toStringAsFixed(2)),
    ]);
  }

  static Future<void> syncAccountBalances(List<AccountBalanceData> accounts) async {
    final json = jsonEncode(accounts.take(6).map((a) => a.toJson()).toList());
    await HomeWidget.saveWidgetData('widget_accounts_json', json);
  }

  static Future<void> syncUpcomingPayments(List<UpcomingItemData> items) async {
    final json = jsonEncode(items.take(8).map((i) => i.toJson()).toList());
    await HomeWidget.saveWidgetData('widget_upcoming_json', json);
  }

  static Future<void> updateAllWidgets() async {
    await Future.wait(
      _qualifiedNames.map(
        (name) => HomeWidget.updateWidget(qualifiedAndroidName: name),
      ),
    );
  }
}
