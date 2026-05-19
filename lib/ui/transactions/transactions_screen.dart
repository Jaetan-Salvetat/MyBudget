import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/loans/loans_screen.dart';
import 'package:mybudget/ui/revenues/revenues_screen.dart';

class TransactionsScreen extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const TransactionsScreen({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

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
              'Transactions',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FrostedTabs(
              tabs: const ['Dépenses', 'Revenus', 'Emprunts'],
              selectedIndex: selectedTab,
              onTabSelected: onTabChanged,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: const [
                ExpensesScreen(),
                RevenuesScreen(),
                LoansScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
