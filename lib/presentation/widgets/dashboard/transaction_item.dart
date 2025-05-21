import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/core/extensions/category_model_extensions.dart';
import 'package:mybudget/data/models/expense_model.dart';

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
    final bool isExpense = transaction is ExpenseModel;
    final Color amountColor = isExpense
        ? Theme.of(context).colorScheme.error
        : Colors.green.shade700;
    
    final double amount = double.tryParse(transaction.amount.toString()) ?? 0.0;
    final String amountText = isExpense
        ? '-${formatter.format(amount)}'
        : '+${formatter.format(amount)}';

    final DateTime date = transaction.date ?? DateTime.now();
    final String dateFormatted = DateFormat('dd/MM/yyyy').format(date);
    
    final categoryController = Get.find<CategoryController>();
    final String categoryName = isExpense 
        ? categoryController.categories.firstWhere(
            (cat) => cat.id == (transaction as ExpenseModel).categoryId,
            orElse: () => CategoryModelExtensions.unknown()
          ).name
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
            color: _getCategoryColor(categoryName).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            _getCategoryIcon(categoryName),
            color: _getCategoryColor(categoryName),
            size: 20,
          ),
        ),
        title: Text(
          transaction.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$categoryName • $dateFormatted',
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
