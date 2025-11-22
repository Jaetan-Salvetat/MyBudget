import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/loan_model.dart';

class LoanDetailsSection extends StatelessWidget {
  final LoanModel loan;

  const LoanDetailsSection({required this.loan, super.key});

  @override
  Widget build(BuildContext context) {
    final nextPaymentDate = _getNextPaymentDate(loan);

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
              context,
              'Statut',
              loan.getAutomaticStatus().label,
              loan.getAutomaticStatus().icon,
              loan.getAutomaticStatus().getColor(context),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              'Date de début',
              DateFormat('dd/MM/yyyy').format(loan.startDate),
              Icons.calendar_today,
              null,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              'Date de fin prévue',
              DateFormat('dd/MM/yyyy').format(loan.endDate),
              Icons.event,
              null,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              'Durée totale',
              '${_calculateLoanDuration(loan)} mois',
              Icons.timelapse,
              null,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              'Jour d\'échéance',
              'Jour ${loan.dayOfMonth} de chaque mois',
              Icons.date_range,
              null,
            ),
            if (nextPaymentDate != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                context,
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
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
    BuildContext context,
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
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
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

  bool _isPaymentSoon(DateTime paymentDate) {
    final now = DateTime.now();
    final difference = paymentDate.difference(now).inDays;
    return difference <= 5;
  }

  int _calculateLoanDuration(LoanModel loan) {
    final startDate = DateTime(loan.startDate.year, loan.startDate.month, 1);
    final endDate = DateTime(loan.endDate.year, loan.endDate.month, 1);
    final months =
        (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
    return months > 0 ? months : 1;
  }
}
