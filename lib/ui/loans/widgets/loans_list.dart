import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/loans/widgets/loan_card.dart';
import 'package:mybudget/ui/loans/widgets/loan_summary_card.dart';
import 'package:mybudget/ui/loans/screens/loan_details_screen.dart';
import 'package:mybudget/ui/loans/widgets/loan_creation_bottom_sheet.dart';
import 'package:mybudget/ui/common/empty_state.dart';

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
    final activeLoanCount = loanVM.getActiveLoans().length;

    final progress =
        totalActiveInitialAmount == 0
            ? 0.0
            : (totalActiveInitialAmount - totalRemainingAmount) /
                totalActiveInitialAmount;

    return LoanSummaryCard(
      totalDebt: totalRemainingAmount,
      monthlyPayment: totalMonthlyPayment,
      progress: progress,
      activeLoanCount: activeLoanCount,
      initialDebt: totalActiveInitialAmount,
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
    return EmptyState(
      message: 'Aucun emprunt enregistré',
      subMessage: 'Ajoutez vos emprunts pour suivre vos remboursements',
      icon: Icons.payments,
      buttonText: 'Ajouter un emprunt',
      onPressed: () {
        final accountVM = Provider.of<AccountViewModel>(context, listen: false);
        final loanVM = Provider.of<LoanViewModel>(context, listen: false);

        LoanCreationBottomSheet.show(
          context: context,
          accounts: accountVM.accounts,
          onSubmit: (newLoan) {
            loanVM.addLoan(newLoan);
          },
          onCancel: () {},
        );
      },
    );
  }
}
