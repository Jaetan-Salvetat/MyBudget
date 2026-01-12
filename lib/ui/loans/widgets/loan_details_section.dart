import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/domain/loan.dart';
import 'package:mybudget/core/enums/loan_enums.dart';

class LoanDetailsSection extends StatelessWidget {
  final Loan loan;

  const LoanDetailsSection({required this.loan, super.key});

  @override
  Widget build(BuildContext context) {
    final nextPaymentDate = _getNextPaymentDate(loan);
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final realDuration =
        loan.duration > 0
            ? loan.duration
            : (loan.endDate.year - loan.startDate.year) * 12 +
                loan.endDate.month -
                loan.startDate.month;
    final years = realDuration ~/ 12;
    final months = realDuration % 12;
    final durationString =
        years > 0
            ? (months > 0 ? '$years ans $months mois' : '$years ans')
            : '$months mois';

    return FrostedCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails du contrat',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Calendrier'),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Date de début',
            DateFormat('dd/MM/yyyy').format(loan.startDate),
            Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Date de fin',
            DateFormat('dd/MM/yyyy').format(loan.endDate),
            Icons.event_outlined,
          ),
          if (nextPaymentDate != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Prochaine échéance',
              DateFormat('dd/MM/yyyy').format(nextPaymentDate),
              Icons.alarm,
              valueColor:
                  _isPaymentSoon(nextPaymentDate)
                      ? Theme.of(context).colorScheme.error
                      : null,
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: FrostedDivider(height: 1),
          ),

          _buildSectionTitle(context, 'Informations'),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Prêteur',
            loan.lenderName,
            Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Taux d\'intérêt',
            '${loan.interestRate.toStringAsFixed(2)}%',
            Icons.percent_outlined,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Durée totale',
            durationString,
            Icons.timelapse_outlined,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Assurance',
            loan.insuranceType == LoanInsuranceType.none
                ? 'Aucune'
                : '${loan.insuranceType.label} (${formatter.format(loan.insuranceValue)})',
            Icons.security_outlined,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Coût total du crédit',
            formatter.format(loan.totalCost),
            Icons.savings_outlined,
            valueColor: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Jour de prélèvement',
            'Le ${loan.dayOfMonth} du mois',
            Icons.date_range_outlined,
          ),

          if (loan.notes != null && loan.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loan.notes!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DateTime? _getNextPaymentDate(Loan loan) {
    if (loan.isCompleted) return null;

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
}
