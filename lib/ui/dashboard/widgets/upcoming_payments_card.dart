import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:mybudget/models/expense_model.dart';

class UpcomingPaymentsCard extends ConsumerWidget {
  final NumberFormat formatter;

  const UpcomingPaymentsCard({required this.formatter, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseNotifier = ref.watch(expenseProvider.notifier);
    final upcomingExpenses = expenseNotifier.getUpcomingExpenses();

    if (upcomingExpenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(child: Text('Aucun paiement prévu')),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: upcomingExpenses.length,
        itemBuilder: (context, index) {
          final expense = upcomingExpenses[index];
          return _HorizontalPaymentCard(
            expense: expense,
            formatter: formatter,
            index: index,
          );
        },
      ),
    );
  }
}

class _HorizontalPaymentCard extends ConsumerWidget {
  final ExpenseModel expense;
  final NumberFormat formatter;
  final int index;

  const _HorizontalPaymentCard({
    required this.expense,
    required this.formatter,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.read(categoryProvider).value ?? [];
    final categoryName =
        categories.isEmpty
            ? '...'
            : categories
                .firstWhere(
                  (cat) => cat.id == expense.categoryId,
                  orElse: () => categories.first,
                )
                .name;

    String dateDisplay;
    final now = DateTime.now();

    if (expense.frequency == 'Mensuel') {
      final isToday = expense.startDate.day == now.day;
      dateDisplay = isToday ? 'Aujourd\'hui' : 'Le ${expense.startDate.day}';
    } else {
      final isToday =
          expense.startDate.day == now.day && expense.startDate.month == now.month;
      dateDisplay =
          isToday
              ? 'Aujourd\'hui'
              : DateFormat('d MMMM', 'fr_FR').format(expense.startDate);
    }

    return FrostedCard(
      margin: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 136,
        height: 116,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 14,
                    color:
                        dateDisplay == 'Aujourd\'hui'
                            ? Colors.green
                            : Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  dateDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        dateDisplay == 'Aujourd\'hui'
                            ? Colors.green
                            : Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              expense.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              formatter.format(expense.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
