import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';
import 'package:mybudget/data/models/loan_model.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
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

    if (loanController.loans.isEmpty) {
      return const Center(
        child: Text('Aucun emprunt enregistré'),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 100, bottom: 16, left: 16, right: 16),
      children: [
        _buildSummaryCard(context),
        const SizedBox(height: 24),
        Text(
          'Emprunts actifs (${activeLoans.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
    final totalActiveInitialAmount = loanController.getTotalActiveInitialAmount();
    final totalRemainingAmount = loanController.getTotalRemainingAmount();
    final totalMonthlyPayment = loanController.getTotalMonthlyPayments();
    final progressValue = _calculateOverallProgress();
    final amountPaid = totalActiveInitialAmount - totalRemainingAmount;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 30, 0, 5),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            // Partie supérieure - Header avec gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.payments,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Récapitulatif des Prêts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (progressValue > 0.5
                                  ? Colors.green.shade700
                                  : Colors.orange)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              progressValue > 0.5
                                  ? Icons.trending_up
                                  : Icons.trending_flat,
                              color: progressValue > 0.5
                                  ? Colors.green.shade700
                                  : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(progressValue * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: progressValue > 0.5
                                    ? Colors.green.shade700
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reste à payer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(totalRemainingAmount),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Partie intermédiaire - Montants des prêts
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFinancialSummary(
                      'Total emprunté',
                      totalActiveInitialAmount,
                      Icons.attach_money,
                      Theme.of(context).colorScheme.error,
                      formatter,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFinancialSummary(
                      'Déjà remboursé',
                      amountPaid,
                      Icons.arrow_upward,
                      Theme.of(context).colorScheme.primary,
                      formatter,
                    ),
                  ),
                ],
              ),
            ),
            
            // Partie inférieure - Paiements mensuels
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
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
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paiement mensuel',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
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
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(String title, double amount, IconData icon, Color color, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, LoanModel loan) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final account = accountController.accounts.firstWhere(
      (a) => a.id == loan.accountId,
      orElse: () => accountController.accounts.first,
    );

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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      account.name,
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Échéance le ${DateFormat('dd/MM/yyyy').format(nextPaymentDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
