import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/loans/widgets/loan_card.dart';
import 'package:mybudget/ui/loans/widgets/loan_summary_card.dart';
import 'package:mybudget/ui/loans/screens/loan_details_screen.dart';
import 'package:mybudget/ui/loans/widgets/loan_creation_bottom_sheet.dart';
import 'package:mybudget/ui/common/empty_state.dart';

class LoansList extends ConsumerWidget {
  const LoansList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanNotifier = ref.watch(loanProvider.notifier);
    final loans = ref.watch(loanProvider).value ?? [];
    final accounts = ref.watch(accountProvider).value ?? [];
    final isLoading = ref.watch(loanProvider).isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeLoans = loanNotifier.getActiveLoans();
    final completedLoans = loanNotifier.getCompletedLoans();
    final isEmpty = loans.isEmpty;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: 16,
        bottom: 100,
        left: 16,
        right: 16,
      ),
      children: [
        _buildSummaryCard(context, ref),
        const SizedBox(height: 24),
        if (isEmpty) _buildEmptyState(context, ref),
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
            (loan) => _buildLoanCard(context, loan, accounts, ref),
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
            (loan) => _buildLoanCard(context, loan, accounts, ref),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref) {
    final totalActiveInitialAmount =
        ref.read(loanProvider.notifier).getTotalActiveInitialAmount();
    final totalRemainingAmount =
        ref.read(loanProvider.notifier).getTotalRemainingAmount();
    final totalMonthlyPayment =
        ref.read(loanProvider.notifier).getTotalMonthlyPayments();
    final totalRemainingCost =
        ref.read(loanProvider.notifier).getTotalRemainingCost();
    final activeLoanCount =
        ref.read(loanProvider.notifier).getActiveLoans().length;

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
      remainingCost: totalRemainingCost,
    );
  }

  Widget _buildLoanCard(
    BuildContext context,
    Loan loan,
    List<AccountModel> accounts,
    WidgetRef ref,
  ) {
    final accountName =
        accounts.isEmpty
            ? 'Compte inconnu'
            : accounts
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return EmptyState(
      message: 'Aucun emprunt enregistré',
      subMessage: 'Ajoutez vos emprunts pour suivre vos remboursements',
      icon: Icons.payments,
      buttonText: 'Ajouter un emprunt',
      onPressed: () {
        final accounts = ref.read(accountProvider).value ?? [];
        final loanNotifier = ref.read(loanProvider.notifier);

        LoanCreationBottomSheet.show(
          context: context,
          accounts: accounts,
          onSubmit: (newLoan) {
            loanNotifier.addLoan(newLoan);
          },
          onCancel: () {},
        );
      },
    );
  }
}
