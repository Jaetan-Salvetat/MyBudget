import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';
import 'package:mybudget/data/models/loan_model.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
import 'package:mybudget/presentation/widgets/common/delete_confirmation_dialog.dart';
import 'package:mybudget/presentation/widgets/common/empty_state_view.dart';
import 'package:mybudget/presentation/widgets/common/financial_summary_card.dart';
import 'package:mybudget/presentation/widgets/loans/loan_bottom_sheet.dart';

class LoansScreen extends StatelessWidget {
  final bool isNested;
  final String fabTag;

  LoansScreen({this.isNested = false, this.fabTag = 'loans_fab', super.key});

  final loanController = Get.find<LoanController>();
  final accountController = Get.find<AccountController>();

  @override
  Widget build(BuildContext context) {
    if (isNested) {
      return Stack(
        children: [
          Obx(() => _buildLoansList(context)),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: fabTag,
              onPressed: () => _showAddLoanBottomSheet(context),
              elevation: 4,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return AppScaffold(
      title: 'Mes Emprunts',
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddLoanBottomSheet(context),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      child: Obx(() => _buildLoansList(context)),
    );
  }

  Widget _buildLoansList(BuildContext context) {
    final activeLoans = loanController.getActiveLoans();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 100, bottom: 16, left: 16, right: 16),
      children: [
        _buildSummaryCard(context),
        const SizedBox(height: 24),
        if (loanController.loans.isEmpty)
          EmptyStateView(
            title: 'Aucun emprunt enregistré',
            message: 'Ajoutez vos emprunts pour suivre vos remboursements',
            icon: Icons.payments,
            buttonText: 'Ajouter un emprunt',
            onButtonPressed: () => _showAddLoanBottomSheet(context),
          ),
        if (activeLoans.isNotEmpty)
          Text(
            'Emprunts actifs (${activeLoans.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        if (activeLoans.isNotEmpty) const SizedBox(height: 16),
        if (activeLoans.isNotEmpty)
          ...activeLoans.map((loan) => _buildLoanCard(context, loan)),

        if (loanController.loans.length > activeLoans.length) ...[
          const SizedBox(height: 32),
          Text(
            'Emprunts remboursés (${loanController.loans.length - activeLoans.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...loanController.loans
              .where((loan) => loan.isCompleted())
              .map((loan) => _buildLoanCard(context, loan)),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final totalActiveInitialAmount =
        loanController.getTotalActiveInitialAmount();
    final totalRemainingAmount = loanController.getTotalRemainingAmount();
    final totalMonthlyPayment = loanController.getTotalMonthlyPayments();
    final progressValue = _calculateOverallProgress();
    final amountPaid = totalActiveInitialAmount - totalRemainingAmount;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final primaryColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 30, 0, 5),
      child: FinancialSummaryCard(
        title: 'Récapitulatif des Prêts',
        titleIcon: Icons.payments,
        primaryColor:
            errorColor, // Utilisation de la couleur d'erreur pour le montant à payer
        amount: totalRemainingAmount,
        formatter: formatter,
        trendIcon:
            progressValue > 0.5 ? Icons.trending_up : Icons.trending_flat,
        trendLabel: '${(progressValue * 100).toStringAsFixed(1)}%',
        childContent: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de progression
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 12,
                  backgroundColor: primaryColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressValue > 0.5 ? Colors.green.shade700 : primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total remboursé',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(amountPaid),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Montant initial',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(totalActiveInitialAmount),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mensuel',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatter.format(totalMonthlyPayment),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLoanCard(BuildContext context, LoanModel loan) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    // Gérer le cas où la liste des comptes est vide
    final accountName =
        accountController.accounts.isEmpty
            ? 'Compte inconnu'
            : accountController.accounts
                .firstWhere(
                  (a) => a.id == loan.accountId,
                  orElse: () => accountController.accounts.first,
                )
                .name;

    final paidAmount = loan.getAutomaticPaidAmount();
    final progress = paidAmount / loan.amount;
    final remainingAmount = loan.amount - paidAmount;
    final nextPaymentDate = _getNextPaymentDate(loan);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToLoanDetails(context, loan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      loan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      accountName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reste: ${formatter.format(remainingAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  Text(
                    'Payé: ${formatter.format(paidAmount)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(8),
                minHeight: 6,
              ),
              if (!loan.isCompleted() && nextPaymentDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Échéance le ${DateFormat('dd/MM/yyyy').format(nextPaymentDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _calculateOverallProgress() {
    final activeLoans = loanController.getActiveLoans();
    final totalAmount = activeLoans.fold(0.0, (sum, loan) => sum + loan.amount);
    final totalPaid = activeLoans.fold(
      0.0,
      (sum, loan) => sum + loan.getAutomaticPaidAmount(),
    );

    if (totalAmount == 0) return 0;
    return totalPaid / totalAmount;
  }

  DateTime? _getNextPaymentDate(LoanModel loan) {
    if (loan.isCompleted()) return null;

    final now = DateTime.now();
    DateTime nextDate;

    if (loan.dayOfMonth >= now.day) {
      nextDate = DateTime(now.year, now.month, loan.dayOfMonth);
    } else {
      nextDate = DateTime(now.year, now.month + 1, loan.dayOfMonth);
    }

    if (nextDate.isAfter(loan.endDate)) {
      return loan.endDate;
    }

    return nextDate;
  }

  void _showAddLoanBottomSheet(BuildContext context) {
    LoanBottomSheet.show(
      context: context,
      accounts: accountController.accounts,
      onSubmit: (loan) {
        loanController.addLoan(loan);
      },
      onCancel: () {},
    );
  }

  void _navigateToLoanDetails(BuildContext context, LoanModel loan) {
    Get.toNamed('/loan-details', arguments: loan);
  }
}
