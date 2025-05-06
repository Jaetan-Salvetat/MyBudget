import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinancialSummaryCard extends StatelessWidget {
  final double totalAssets;
  final double totalLiabilities;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double savingsRate;
  final NumberFormat formatter;

  const FinancialSummaryCard({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.savingsRate,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final netWorth = totalAssets - totalLiabilities;
    final disposableIncome = monthlyIncome - monthlyExpenses;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Résumé financier',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Patrimoine net',
                    formatter.format(netWorth),
                    netWorth >= 0 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Disponible mensuel',
                    formatter.format(disposableIncome),
                    disposableIncome >= 0 
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Taux d\'épargne',
                    '${savingsRate.toStringAsFixed(1)}%',
                    savingsRate > 20 
                        ? Colors.green.shade700 
                        : savingsRate > 0 
                            ? Colors.orange
                            : Theme.of(context).colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Ratio dette/revenu',
                    '${_calculateDebtToIncomeRatio().toStringAsFixed(1)}%',
                    _calculateDebtToIncomeRatio() < 35 
                        ? Colors.green.shade700
                        : _calculateDebtToIncomeRatio() < 45 
                            ? Colors.orange
                            : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Divider(height: 1),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFinancialColumn(
                  context,
                  'Actifs',
                  totalAssets,
                  Theme.of(context).colorScheme.primary,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                _buildFinancialColumn(
                  context,
                  'Dettes',
                  totalLiabilities,
                  Theme.of(context).colorScheme.error,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                _buildFinancialColumn(
                  context,
                  'Revenus',
                  monthlyIncome,
                  Colors.green.shade700,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                _buildFinancialColumn(
                  context,
                  'Dépenses',
                  monthlyExpenses,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialColumn(BuildContext context, String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  double _calculateDebtToIncomeRatio() {
    if (monthlyIncome <= 0) return 100.0;
    
    final monthlyDebtPayments = totalLiabilities * 0.05;
    return (monthlyDebtPayments / monthlyIncome) * 100;
  }
}
