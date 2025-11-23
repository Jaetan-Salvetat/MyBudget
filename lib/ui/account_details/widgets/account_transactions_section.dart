import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/account_details/widgets/account_expense_list.dart';
import 'package:mybudget/ui/account_details/widgets/account_revenue_list.dart';
import 'package:mybudget/ui/account_details/widgets/account_loan_list.dart';

class AccountTransactionsSection extends StatefulWidget {
  final AccountModel account;
  final ExpenseViewModel expenseVM;
  final RevenueViewModel revenueVM;
  final LoanViewModel loanVM;
  final NumberFormat formatter;

  const AccountTransactionsSection({
    required this.account,
    required this.expenseVM,
    required this.revenueVM,
    required this.loanVM,
    required this.formatter,
    super.key,
  });

  @override
  State<AccountTransactionsSection> createState() =>
      _AccountTransactionsSectionState();
}

class _AccountTransactionsSectionState
    extends State<AccountTransactionsSection> {
  int _selectedIndex = 0;
  final List<String> _tabLabels = ['Dépenses', 'Revenus', 'Mensualités'];

  @override
  Widget build(BuildContext context) {
    final expenses = widget.expenseVM.getExpensesForAccount(widget.account.id);
    final revenues = widget.revenueVM.getRevenuesForAccount(widget.account.id);
    final loans = widget.loanVM.getActiveLoansForAccount(widget.account.id);

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
