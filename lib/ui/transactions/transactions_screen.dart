import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/expense_group_by.dart';
import 'package:mybudget/core/providers/expenses_view_provider.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/loans/loans_screen.dart';
import 'package:mybudget/ui/loans/widgets/loan_creation_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/revenues/revenues_screen.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                    icon: Icons.add_rounded,
                    onPressed: () => _handleAdd(context, ref),
                  ),
                  const SizedBox(width: 4),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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

  void _handleAdd(BuildContext context, WidgetRef ref) {
    switch (selectedTab) {
      case 0:
        _showAddExpenseBottomSheet(context, ref);
      case 1:
        _showAddRevenueBottomSheet(context, ref);
      case 2:
        _showAddLoanBottomSheet(context, ref);
    }
  }

  void _showAddExpenseBottomSheet(BuildContext context, WidgetRef ref) {
    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'une dépense');
      return;
    }
    ExpenseBottomSheet.show(
      context: context,
      accounts: accounts,
      categories: ref.read(categoryProvider).value ?? [],
      closedExpenses: ref.read(expenseProvider.notifier).getClosedExpenses(),
      onSubmit: (expense) async {
        try {
          await ref.read(expenseProvider.notifier).addExpense(expense);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de l\'ajout: $e',
            );
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showAddRevenueBottomSheet(BuildContext context, WidgetRef ref) {
    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'un revenu');
      return;
    }

    RevenueBottomSheet.show(
      context: context,
      accounts: accounts,
      closedRevenues: ref.read(revenueProvider.notifier).getClosedRevenues(),
      onSubmit: (revenue) async {
        try {
          await ref.read(revenueProvider.notifier).addRevenue(revenue);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de l\'ajout: $e',
            );
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showAddLoanBottomSheet(BuildContext context, WidgetRef ref) {
    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'un emprunt');
      return;
    }

    LoanCreationBottomSheet.show(
      context: context,
      accounts: accounts,
      onSubmit: (loan) async {
        try {
          await ref.read(loanProvider.notifier).addLoan(loan);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de l\'ajout: $e',
            );
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showNoAccountDialog(BuildContext context, String action) {
    FrostedDialog.show(
      context: context,
      barrierDismissible: false,
      title: const Text('Aucun compte disponible'),
      content: Text(
        'Vous devez d\'abord créer un compte avant d\'ajouter $action.',
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}


class _GroupByToggle extends StatelessWidget {
  final ExpenseGroupBy value;
  final ValueChanged<ExpenseGroupBy> onChanged;

  const _GroupByToggle({required this.value, required this.onChanged});

  static const Duration _animationDuration = Duration(milliseconds: 220);
  static const Curve _animationCurve = Curves.easeOutCubic;
  static const double _itemHeight = 28;
  static const double _itemWidth = 70;
  static const double _padding = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = ExpenseGroupBy.values;
    final selectedIndex = options.indexOf(value);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: SizedBox(
        height: _itemHeight,
        width: _itemWidth * options.length,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: _animationDuration,
              curve: _animationCurve,
              left: selectedIndex * _itemWidth,
              top: 0,
              bottom: 0,
              width: _itemWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (final option in options)
                  _ToggleItem(
                    label: option.label,
                    selected: option == value,
                    width: _itemWidth,
                    onTap: () => onChanged(option),
                    duration: _animationDuration,
                    curve: _animationCurve,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool selected;
  final double width;
  final VoidCallback onTap;
  final Duration duration;
  final Curve curve;

  const _ToggleItem({
    required this.label,
    required this.selected,
    required this.width,
    required this.onTap,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
