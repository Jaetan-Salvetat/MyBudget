import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/transfer.dart';
import 'package:mybudget/models/account_model.dart';

class AccountTransferList extends StatelessWidget {
  final List<Transfer> transfers;
  final int currentAccountId;
  final List<AccountModel> accounts;
  final NumberFormat formatter;
  final Function(Transfer)? onTap;

  const AccountTransferList({
    required this.transfers,
    required this.currentAccountId,
    required this.accounts,
    required this.formatter,
    this.onTap,
    super.key,
  });

  String _accountName(int accountId) {
    final account = accounts.where((a) => a.id == accountId).firstOrNull;
    return account?.name ?? 'Compte inconnu';
  }

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("Aucun virement")),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transfers.length,
      separatorBuilder:
          (context, index) => FrostedDivider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        final isOutgoing = transfer.isOutgoingFrom(currentAccountId);
        final color = isOutgoing
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;
        final icon = isOutgoing ? Icons.arrow_upward : Icons.arrow_downward;
        final subtitle = isOutgoing
            ? 'Vers ${_accountName(transfer.toAccountId)}'
            : 'Depuis ${_accountName(transfer.fromAccountId)}';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            transfer.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '$subtitle · ${DateFormat('dd/MM/yyyy').format(transfer.date)}',
          ),
          trailing: Text(
            '${isOutgoing ? '-' : '+'}${formatter.format(transfer.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          onTap: onTap != null ? () => onTap!(transfer) : null,
        );
      },
    );
  }
}
