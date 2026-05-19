import 'package:flutter/material.dart';
import 'package:mybudget/ui/accounts/widgets/account_list.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Mes comptes',
              style: TextStyle(
                fontSize: 22,
                height: 26 / 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: scheme.onSurface,
              ),
            ),
          ),
          const MonthSelector(),
          const SizedBox(height: 4),
          const Expanded(child: AccountList()),
        ],
      ),
    );
  }
}
