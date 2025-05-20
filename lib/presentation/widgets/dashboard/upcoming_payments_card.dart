import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/extensions/expense_extensions.dart';
import 'package:mybudget/data/models/category_model.dart';

class UpcomingPaymentsCard extends StatefulWidget {
  final NumberFormat formatter;

  const UpcomingPaymentsCard({
    required this.formatter,
    Key? key,
  }) : super(key: key);

  @override
  State<UpcomingPaymentsCard> createState() => _UpcomingPaymentsCardState();
}

class _UpcomingPaymentsCardState extends State<UpcomingPaymentsCard> {
  @override
  Widget build(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();

    return Obx(() {
      final upcomingExpenses = expenseController.getUpcomingPayments();
      
      if (upcomingExpenses.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: Text('Aucun paiement prévu'),
          ),
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
            return HorizontalPaymentCard(
              expense: expense,
              formatter: widget.formatter,
              index: index,
            );
          },
        ),
      );
    });
  }
}

class HorizontalPaymentCard extends StatelessWidget {
  final dynamic expense;
  final NumberFormat formatter;
  final int index;

  const HorizontalPaymentCard({
    required this.expense,
    required this.formatter,
    required this.index,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    
    final category = categoryController.categories.firstWhere(
      (cat) => cat.id == expense.categoryId,
      orElse: () => CategoryModel()..name = 'Autre'
    );
    
    final String formattedDate = DateFormat('dd/MM').format(expense.date);
    final bool isToday = expense.date.day == DateTime.now().day &&
                        expense.date.month == DateTime.now().month &&
                        expense.date.year == DateTime.now().year;
    
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isToday ? Colors.green : Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isToday ? 'Aujourd\'hui' : formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday ? Colors.green : Colors.blueGrey,
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
                category.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
      ),
    );
  }
}
