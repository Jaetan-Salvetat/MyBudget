import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/enums/expense_group_by.dart';
import 'package:mybudget/core/providers/expenses_view_provider.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/expenses/expenses_screen.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/expenses/screens/expense_form_screen.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/loans/loans_screen.dart';
import 'package:mybudget/ui/loans/screens/loan_creation_screen.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/revenues/revenues_screen.dart';
import 'package:mybudget/ui/revenues/screens/revenue_form_screen.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';

const double _kGroupBySegmentWidth = 70;

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selectedTab = ref.watch(
      homeNavigationProvider.select((state) => state.transactionsTab),
    );
    final isExpensesTab = selectedTab == TransactionsTab.expenses;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: kMainFlowTopBarPadding.copyWith(
              left: kMainFlowGutter,
              right: kMainFlowGutter,
            ),
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
                  FrostedIconButton.tonal(
                    icon: Symbols.add_rounded,
                    onPressed: () => _handleAdd(context, ref, selectedTab),
                  ),
                  const SizedBox(width: 4),
                  FrostedIconButton.tonal(
                    icon: Symbols.settings_rounded,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kMainFlowGutter),
            child: Row(
              children: [
                const Expanded(
                  child: MonthSelector(alignment: Alignment.centerLeft),
                ),
                if (isExpensesTab) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FrostedSegmentedControl(
                      segments: <String>[
                        for (final option in ExpenseGroupBy.values)
                          option.label,
                      ],
                      currentIndex: ExpenseGroupBy.values.indexOf(
                        ref.watch(expensesGroupByProvider),
                      ),
                      segmentWidth: _kGroupBySegmentWidth,
                      onTap: (index) => ref
                          .read(expensesGroupByProvider.notifier)
                          .set(ExpenseGroupBy.values[index]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kMainFlowGutter,
              12,
              kMainFlowGutter,
              0,
            ),
            child: FrostedTabs(
              tabs: const <FrostedTab>[
                FrostedTab(label: 'Dépenses'),
                FrostedTab(label: 'Revenus'),
                FrostedTab(label: 'Emprunts'),
              ],
              currentIndex: selectedTab.index,
              onTap: (index) => ref
                  .read(homeNavigationProvider.notifier)
                  .selectTransactionsTab(TransactionsTab.values[index]),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedTab.index,
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

  void _handleAdd(BuildContext context, WidgetRef ref, TransactionsTab tab) {
    switch (tab) {
      case TransactionsTab.expenses:
        _openExpenseForm(context, ref);
      case TransactionsTab.revenues:
        _openRevenueForm(context, ref);
      case TransactionsTab.loans:
        _openLoanForm(context, ref);
    }
  }

  Future<void> _openExpenseForm(BuildContext context, WidgetRef ref) async {
    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'une dépense');
      return;
    }

    final expense = await ExpenseFormScreen.push(
      context: context,
      accounts: accounts,
      closedExpenses: ref.read(expenseProvider.notifier).getClosedExpenses(),
    );
    if (expense == null || !context.mounted) return;

    await _persist(
      context,
      () => ref.read(expenseProvider.notifier).addExpense(expense),
    );
  }

  Future<void> _openRevenueForm(BuildContext context, WidgetRef ref) async {
    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'un revenu');
      return;
    }

    final revenue = await RevenueFormScreen.push(
      context: context,
      accounts: accounts,
      closedRevenues: ref.read(revenueProvider.notifier).getClosedRevenues(),
    );
    if (revenue == null || !context.mounted) return;

    await _persist(
      context,
      () => ref.read(revenueProvider.notifier).addRevenue(revenue),
    );
  }

  Future<void> _openLoanForm(BuildContext context, WidgetRef ref) async {
    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'un emprunt');
      return;
    }

    final loan = await LoanCreationScreen.push(
      context: context,
      accounts: accounts,
    );
    if (loan == null || !context.mounted) return;

    await _persist(
      context,
      () => ref.read(loanProvider.notifier).addLoan(loan),
    );
  }

  Future<void> _persist(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout: $e');
      }
    }
  }

  void _showNoAccountDialog(BuildContext context, String action) {
    showFrostedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FrostedDialog(
        title: 'Aucun compte disponible',
        body: Text(
          'Vous devez d\'abord créer un compte avant d\'ajouter $action.',
        ),
        actions: [
          FrostedButton.text(
            label: 'OK',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
