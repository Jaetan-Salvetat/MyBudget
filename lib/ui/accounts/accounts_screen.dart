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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mes comptes',
                    style: TextStyle(
                      fontSize: 28,
                      height: 34 / 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.022 * 28,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const MonthSelector(),
            const SizedBox(height: 4),
            const AccountList(),
          ],
        ),
      ),
    );
  }
}
