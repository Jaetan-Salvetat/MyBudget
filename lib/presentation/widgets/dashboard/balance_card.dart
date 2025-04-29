import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double netFlow;
  final double savingsRate;
  final NumberFormat formatter;

  const BalanceCard({
    required this.balance,
    required this.netFlow,
    required this.savingsRate,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color balanceColor = balance >= 0 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    
    final Color netFlowColor = netFlow >= 0 
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      child: Card(
        elevation: 10,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solde total',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(balance),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: netFlowColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          netFlow >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: netFlowColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatter.format(netFlow),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: netFlowColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(context, 'Économies', formatter.format(netFlow > 0 ? netFlow : 0),
                      netFlow > 0 ? Colors.green.shade700 : Colors.grey),
                  _buildInfoColumn(context, 'Taux d\'épargne', '${savingsRate.toStringAsFixed(1)}%',
                      savingsRate > 20 ? Colors.green.shade700 : Colors.orange),
                  _buildInfoColumn(context, 'Période', 'Mensuel', Colors.blueGrey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoColumn(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
