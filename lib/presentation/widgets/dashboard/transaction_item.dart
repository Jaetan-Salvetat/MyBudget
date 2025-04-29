import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/domain/entities/expense.dart';

class TransactionItem extends StatelessWidget {
  final dynamic transaction; // Either Expense or Revenue
  final NumberFormat formatter;

  const TransactionItem({
    required this.transaction,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isExpense = transaction is Expense;
    final Color amountColor = isExpense
        ? Theme.of(context).colorScheme.error
        : Colors.green.shade700;
    
    final double amount = double.tryParse(transaction.amount.toString()) ?? 0.0;
    final String amountText = isExpense
        ? '-${formatter.format(amount)}'
        : '+${formatter.format(amount)}';

    final DateTime date = transaction.date ?? DateTime.now();
    final String dateFormatted = DateFormat('dd/MM/yyyy').format(date);
    
    // Déterminer la catégorie (existante pour Expense, valeur par défaut pour Revenue)
    final String category = isExpense 
        ? (transaction as Expense).category
        : 'Revenu';
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            _getCategoryIcon(category),
            color: _getCategoryColor(category),
            size: 20,
          ),
        ),
        title: Text(
          transaction.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${category} • ${dateFormatted}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Text(
          amountText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amountColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'alimentation':
        return Colors.green;
      case 'transport':
        return Colors.blue;
      case 'logement':
        return Colors.orange;
      case 'santé':
        return Colors.red;
      case 'loisirs':
        return Colors.purple;
      case 'salaire':
        return Colors.teal;
      case 'investissement':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'alimentation':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'logement':
        return Icons.home;
      case 'santé':
        return Icons.medical_services;
      case 'loisirs':
        return Icons.sports_esports;
      case 'salaire':
        return Icons.work;
      case 'investissement':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }
}
