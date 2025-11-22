import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/loans/widgets/loan_card.dart';
import 'package:mybudget/ui/loans/widgets/loan_bottom_sheet.dart';
import 'package:mybudget/ui/loans/screens/loan_details_screen.dart';
import 'package:mybudget/ui/expenses/widgets/financial_summary_card.dart';

class LoansList extends StatelessWidget {
  const LoansList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoanViewModel, AccountViewModel>(
      builder: (context, loanVM, accountVM, child) {
        if (loanVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeLoans = loanVM.getActiveLoans();
        final completedLoans = loanVM.getCompletedLoans();
        final isEmpty = loanVM.loans.isEmpty;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 100,
            left: 16,
            right: 16,
          ),
          children: [
            _buildSummaryCard(context, loanVM),
            const SizedBox(height: 24),
            if (isEmpty) _buildEmptyState(context),
            if (activeLoans.isNotEmpty) ...[
              Text(
                'Emprunts actifs (${activeLoans.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...activeLoans.map(
                (loan) => _buildLoanCard(context, loan, accountVM, loanVM),
              ),
            ],
            if (completedLoans.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Emprunts remboursés (${completedLoans.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...completedLoans.map(
                (loan) => _buildLoanCard(context, loan, accountVM, loanVM),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, LoanViewModel loanVM) {
    final totalActiveInitialAmount = loanVM.getTotalActiveInitialAmount();
    final totalRemainingAmount = loanVM.getTotalRemainingAmount();
    final totalMonthlyPayment = loanVM.getTotalMonthlyPayments();

     
    final activeLoans = loanVM.getActiveLoans();
    final totalAmount = activeLoans.fold(0.0, (sum, loan) => sum + loan.amount);
    final totalPaid = activeLoans.fold(
      0.0,
      (sum, loan) => sum + loan.getAutomaticPaidAmount(),
    );
    final progressValue = totalAmount == 0 ? 0.0 : totalPaid / totalAmount;

    final amountPaid = totalActiveInitialAmount - totalRemainingAmount;

    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final primaryColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 15, 0, 5),
      child: FinancialSummaryCard(
        title: 'Récapitulatif des Prêts',
        titleIcon: Icons.payments,
        primaryColor: errorColor,
        amount: totalRemainingAmount,
        formatter: formatter,
        trendIcon:
            progressValue > 0.5 ? Icons.trending_up : Icons.trending_flat,
        itemCount: activeLoans.length,
        childContent: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 12,
                  backgroundColor: primaryColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressValue > 0.5
                        ? Theme.of(context).colorScheme.primary
                        : primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      context: context,
                      title: 'Total remboursé',
                      amount: amountPaid,
                      color: Theme.of(context).colorScheme.primary,
                      formatter: formatter,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatBox(
                      context: context,
                      title: 'Montant initial',
                      amount: totalActiveInitialAmount,
                      color: primaryColor,
                      formatter: formatter,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      context: context,
                      title: 'Mensuel',
                      amount: totalMonthlyPayment,
                      color: primaryColor,
                      formatter: formatter,
                      icon: Icons.calendar_today,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
    required NumberFormat formatter,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(
    BuildContext context,
    LoanModel loan,
    AccountViewModel accountVM,
    LoanViewModel loanVM,
  ) {
    final accountName =
        accountVM.accounts.isEmpty
            ? 'Compte inconnu'
            : accountVM.accounts
                .firstWhere(
                  (a) => a.id == loan.accountId,
                  orElse:
                      () =>
                          AccountModel.create(name: 'Compte inconnu', bank: ''),
                )
                .name;

    return LoanCard(
      loan: loan,
      accountName: accountName,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanDetailsScreen(loan: loan),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(
            Icons.payments,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun emprunt enregistré',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos emprunts pour suivre vos remboursements',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
