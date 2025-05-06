import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/data/models/loan_model.dart';
import 'package:get/get.dart';

class ActiveLoansCard extends StatelessWidget {
  final List<LoanModel> loans;
  final NumberFormat formatter;
  
  const ActiveLoansCard({
    required this.loans,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final activeLoans = loans.where((loan) => !loan.isCompleted()).toList();
    
    if (activeLoans.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Emprunts actifs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des prêts actifs
          ...activeLoans.take(3).map((loan) => _buildLoanItem(context, loan)),
          
          // Voir tous les prêts
          if (activeLoans.length > 3) 
            InkWell(
              onTap: () => Get.toNamed('/loans'),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Voir tous les emprunts (${activeLoans.length})',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLoanItem(BuildContext context, LoanModel loan) {
    final nextPaymentDate = _getNextPaymentDate(loan);
    final paidAmount = loan.getAutomaticPaidAmount();
    final progress = paidAmount / loan.amount;
    final status = loan.getAutomaticStatus();
    
    return InkWell(
      onTap: () => Get.toNamed('/loan-details', arguments: loan),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loan.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: status.getColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status.icon,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(8),
              minHeight: 4,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reste: ${formatter.format(loan.amount - paidAmount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                if (nextPaymentDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: _isPaymentSoon(nextPaymentDate)
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM').format(nextPaymentDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isPaymentSoon(nextPaymentDate)
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (loans.indexOf(loan) != loans.length - 1)
              const Divider(height: 16),
          ],
        ),
      ),
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
}
