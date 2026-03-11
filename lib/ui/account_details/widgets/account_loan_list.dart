import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/loan.dart';

class AccountLoanList extends StatelessWidget {
  final List<Loan> loans;
  final NumberFormat formatter;

  const AccountLoanList({
    required this.loans,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("Aucun prêt")),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loans.length,
      separatorBuilder:
          (context, index) => Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.1),
            child: Icon(
              Icons.account_balance,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
          ),
          title: Text(
            loan.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: const Text('Mensualité'),
          trailing: Text(
            formatter.format(loan.currentMonthlyPayment),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        );
      },
    );
  }
}
