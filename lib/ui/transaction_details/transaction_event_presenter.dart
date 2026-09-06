import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/entities/transaction_change_entry.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/transaction_event_model.dart';

class TransactionEventPresenter {
  const TransactionEventPresenter({
    required this.resolver,
    required this.accounts,
    required this.beneficiaries,
  });
  final CategoryDisplayResolver? resolver;
  final List<AccountModel> accounts;
  final List<Beneficiary> beneficiaries;

  TransactionChangeEntry describe(TransactionEventModel event) {
    final change = event.changeEnum;
    return TransactionChangeEntry(
      at: event.at,
      change: change,
      from: _label(change, event.previousValue),
      to: _label(change, event.nextValue),
    );
  }

  String? _label(TransactionChange change, String? raw) {
    if (raw == null) return null;

    return switch (change) {
      TransactionChange.amount => _amountLabel(raw),
      TransactionChange.category => resolver?.resolve(raw)?.label ?? raw,
      TransactionChange.account => _accountLabel(raw),
      TransactionChange.beneficiary => _beneficiaryLabel(raw),
      _ => raw,
    };
  }

  String _amountLabel(String raw) {
    final amount = double.tryParse(raw);
    return amount == null ? raw : MoneyFormatter.format(amount);
  }

  String _accountLabel(String raw) {
    final id = int.tryParse(raw);
    final account = accounts.where((a) => a.id == id).firstOrNull;
    return account?.name ?? raw;
  }

  String _beneficiaryLabel(String raw) {
    final id = int.tryParse(raw);
    final beneficiary = beneficiaries.where((b) => b.id == id).firstOrNull;
    return beneficiary?.name ?? raw;
  }
}
