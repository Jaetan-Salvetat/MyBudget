import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/expense_group_by.dart';
import 'package:mybudget/core/providers/expenses_view_provider.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/loans/loans_screen.dart';
import 'package:mybudget/ui/revenues/revenues_screen.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const TransactionsScreen({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isExpensesTab = selectedTab == 0;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 28,
                        height: 34 / 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.022 * 28,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  FrostedControlButton(
                    icon: Icons.settings_rounded,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: MonthSelector(alignment: Alignment.centerLeft),
                ),
                if (isExpensesTab) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GroupByToggle(
                      value: ref.watch(expensesGroupByProvider),
                      onChanged: (value) => ref
                          .read(expensesGroupByProvider.notifier)
                          .set(value),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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

class _GroupByToggle extends StatelessWidget {
  final ExpenseGroupBy value;
  final ValueChanged<ExpenseGroupBy> onChanged;

  const _GroupByToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in ExpenseGroupBy.values)
            _ToggleItem(
              label: option.label,
              selected: option == value,
              onTap: () => onChanged(option),
            ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
