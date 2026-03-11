import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/account_details/widgets/account_expense_list.dart';
import 'package:mybudget/ui/account_details/widgets/account_revenue_list.dart';
import 'package:mybudget/ui/account_details/widgets/account_loan_list.dart';

class AccountTransactionsSection extends ConsumerStatefulWidget {
  final AccountModel account;
  final NumberFormat formatter;

  const AccountTransactionsSection({
    required this.account,
    required this.formatter,
    super.key,
  });

  @override
  ConsumerState<AccountTransactionsSection> createState() =>
      _AccountTransactionsSectionState();
}

class _AccountTransactionsSectionState
    extends ConsumerState<AccountTransactionsSection> {
  int _selectedIndex = 0;
  final List<String> _tabLabels = ['Dépenses', 'Revenus', 'Mensualités'];

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider.notifier).getExpensesForAccount(widget.account.id);
    final revenues = ref.watch(revenueProvider.notifier).getRevenuesForAccount(widget.account.id);
    final loans = ref.watch(loanProvider.notifier).getActiveLoansForAccount(widget.account.id);

    return FrostedCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expenses.isEmpty && revenues.isEmpty && loans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune transaction',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                FrostedTabs(
                  tabs: _tabLabels,
                  selectedIndex: _selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
                Builder(
                  builder: (context) {
                    switch (_selectedIndex) {
                      case 0:
                        return AccountExpenseList(
                          expenses: expenses,
                          formatter: widget.formatter,
                        );
                      case 1:
                        return AccountRevenueList(
                          revenues: revenues,
                          formatter: widget.formatter,
                        );
                      case 2:
                        return AccountLoanList(
                          loans: loans,
                          formatter: widget.formatter,
                        );
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
