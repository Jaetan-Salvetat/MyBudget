import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/revenue_model.dart';

class AccountRevenueList extends StatelessWidget {
  final List<RevenueModel> revenues;
  final NumberFormat formatter;

  const AccountRevenueList({
    required this.revenues,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (revenues.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("Aucun revenu")),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: revenues.length,
      separatorBuilder:
          (context, index) => Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
      itemBuilder: (context, index) {
        final revenue = revenues[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.arrow_upward,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            revenue.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(revenue.date)),
          trailing: Text(
            formatter.format(revenue.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}
