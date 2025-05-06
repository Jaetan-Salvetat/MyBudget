import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/data/models/loan_model.dart';
import 'package:mybudget/presentation/widgets/loans/loan_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';

class LoanDetailsScreen extends StatefulWidget {
  const LoanDetailsScreen({super.key});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  final LoanController loanController = Get.find<LoanController>();
  final AccountController accountController = Get.find<AccountController>();

  late LoanModel loan;

  final formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    loan = Get.arguments as LoanModel;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Détails de l\'emprunt',
      hideBottomBar: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditLoanBottomSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteConfirmation(context),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: 130,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoanHeader(context),
            const SizedBox(height: 24),
            _buildProgressSection(context),
            const SizedBox(height: 24),
            _buildDetailsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanHeader(BuildContext context) {
    final account = accountController.accounts.firstWhere(
      (a) => a.id == loan.accountId,
      orElse: () => accountController.accounts.first,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prêteur: ${loan.lenderName}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  context,
                  'Montant total',
                  formatter.format(loan.amount),
                  Icons.euro,
                ),
                _buildInfoItem(
                  context,
                  'Mensualité',
                  formatter.format(loan.monthlyPayment),
                  Icons.calendar_view_month,
                ),
                _buildInfoItem(
                  context,
                  'Reste à payer',
                  formatter.format(loan.getRemainingAmount()),
                  Icons.payment,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  context,
                  'Durée totale',
                  '${_calculateLoanDuration(loan)} mois',
                  Icons.date_range,
                ),
                _buildInfoItem(
                  context,
                  'Compte',
                  account.name,
                  Icons.account_balance_wallet,
                ),
                _buildInfoItem(
                  context,
                  'Taux effectif',
                  '${_calculateEffectiveRate(loan)}%',
                  Icons.percent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final paidAmount = loan.getAutomaticPaidAmount();
    final progress = paidAmount / loan.amount;
    final remainingAmount = loan.amount - paidAmount;
    final progressText = '${(progress * 100).toInt()}%';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progression du remboursement',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                Text(
                  progressText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        progress > 0.5
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payé: ${formatter.format(paidAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'Reste: ${formatter.format(remainingAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${formatter.format(loan.amount)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final nextPaymentDate = _getNextPaymentDate();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Statut',
              _getStatusText(loan.getAutomaticStatus()),
              _getStatusIcon(loan.getAutomaticStatus()),
              _getStatusColor(context, loan.getAutomaticStatus()),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Date de début',
              DateFormat('dd/MM/yyyy').format(loan.startDate),
              Icons.calendar_today,
              null,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Date de fin prévue',
              DateFormat('dd/MM/yyyy').format(loan.endDate),
              Icons.event,
              null,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Jour d\'échéance',
              'Jour ${loan.dayOfMonth} de chaque mois',
              Icons.date_range,
              null,
            ),
            if (nextPaymentDate != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Prochaine échéance',
                DateFormat('dd/MM/yyyy').format(nextPaymentDate),
                Icons.alarm,
                _isPaymentSoon(nextPaymentDate)
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ],
            if (loan.notes != null && loan.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(loan.notes!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color? iconColor,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context, LoanStatus status) {
    return status.getColor(context);
  }

  String _getStatusText(LoanStatus status) {
    return status.label;
  }

  IconData _getStatusIcon(LoanStatus status) {
    return status.icon;
  }

  DateTime? _getNextPaymentDate() {
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

  bool _isPaymentSoon(DateTime paymentDate) {
    final now = DateTime.now();
    final difference = paymentDate.difference(now).inDays;
    return difference <= 5;
  }

  void _showEditLoanBottomSheet(BuildContext context) {
    LoanBottomSheet.show(
      context: context,
      accounts: accountController.accounts,
      loan: loan,
      onSubmit: (updatedLoan) {
        loanController.updateLoan(updatedLoan);
        setState(() {
          loan = updatedLoan;
        });
        Get.snackbar(
          'Emprunt mis à jour',
          'Les informations ont été mises à jour avec succès.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      onCancel: () {},
    );
  }

  int _calculateLoanDuration(LoanModel loan) {
    // Calcul du nombre de mois entre la date de début et la date de fin
    final startDate = DateTime(loan.startDate.year, loan.startDate.month, 1);
    final endDate = DateTime(loan.endDate.year, loan.endDate.month, 1);
    final months =
        (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
    return months > 0 ? months : 1;
  }

  String _calculateEffectiveRate(LoanModel loan) {
    // Calcul approximatif du taux d'intérêt en utilisant la formule de crédit
    // Cette méthode est une simplification pour illustration
    final months = _calculateLoanDuration(loan);
    final totalPayment = loan.monthlyPayment * months;

    if (loan.amount <= 0 || totalPayment <= loan.amount) {
      return '0.0'; // Pas d'intérêt ou données invalides
    }

    // Différence entre ce qui est payé et le montant du prêt = intérêts
    final interestAmount = totalPayment - loan.amount;

    // Taux d'intérêt simple annualisé (approximatif)
    final yearRate = (interestAmount / loan.amount) * (12 / months) * 100;

    return yearRate.toStringAsFixed(2);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer l\'emprunt'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cet emprunt ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  loanController.deleteLoan(loan.id);
                  Get.back();
                  Get.snackbar(
                    'Emprunt supprimé',
                    'L\'emprunt a été supprimé avec succès.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
