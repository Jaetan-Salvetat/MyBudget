import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/presentation/widgets/common/delete_confirmation_dialog.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String accountName;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ExpenseCard({
    required this.expense,
    required this.accountName,
    required this.onDelete,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.1), width: 1)
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.categoryId),
                      color: colorScheme.onErrorContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 14,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              accountName,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${expense.amount.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (expense.frequency != 'Unique')
                    _buildInfoChip(
                      context: context,
                      label: expense.frequency,
                      icon: Icons.repeat,
                      backgroundColor: colorScheme.primaryContainer,
                      textColor: colorScheme.onPrimaryContainer,
                    ),
                  if (expense.frequency != 'Unique')
                    const SizedBox(width: 8),
                  _buildInfoChip(
                    context: context,
                    label: _formatDate(expense.date, expense.frequency),
                    icon: Icons.calendar_today,
                    backgroundColor: colorScheme.secondaryContainer,
                    textColor: colorScheme.onSecondaryContainer,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer.withOpacity(0.2),
                      minimumSize: const Size(36, 36),
                    ),
                    onPressed: () {
                      DeleteConfirmationDialog.show(
                        context: context,
                        title: 'Confirmer la suppression',
                        message: 'Voulez-vous vraiment supprimer ${expense.name} ?',
                        onConfirm: onDelete,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(int categoryId) {
    final categoryController = Get.find<CategoryController>();
    final category = categoryController.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel()..icon = 'category',
    );
    
    return category.getIconData();
  }

  String _formatDate(DateTime date, String frequency) {
    switch (frequency) {
      case 'Unique':
        return '${date.day}/${date.month}/${date.year}';
      case 'Mensuel':
        return 'Jour ${date.day}';
      case 'Hebdomadaire':
        final days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
        return days[date.weekday % 7];
      case 'Annuel':
        final months = [
          'Jan',
          'Fév',
          'Mar',
          'Avr',
          'Mai',
          'Juin',
          'Juil',
          'Août',
          'Sep',
          'Oct',
          'Nov',
          'Déc',
        ];
        return '${date.day} ${months[date.month - 1]}';
      default:
        return '${date.day}/${date.month}/${date.year}';
    }
  }
}
