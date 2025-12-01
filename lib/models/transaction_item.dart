import 'package:flutter/material.dart';

enum TransactionType {
  income,
  expense,
  transfer,
  loan;

  IconData get icon {
    switch (this) {
      case TransactionType.income:
        return Icons.attach_money;
      case TransactionType.expense:
        return Icons.money_off;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.loan:
        return Icons.account_balance_wallet;
    }
  }
}

class TransactionItem {
  final int id;
  final String label;
  final TransactionType type;
  final double amount;
  final DateTime date;

  TransactionItem({
    required this.id,
    required this.label,
    required this.type,
    required this.amount,
    required this.date,
  });
}
