import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseDayHeader extends StatelessWidget {
  final DateTime date;
  final int count;
  final double total;
  final bool isToday;

  const ExpenseDayHeader({
    required this.date,
    required this.count,
    required this.total,
    required this.isToday,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dayLabel = DateFormat('EEE d MMM', 'fr_FR').format(date);
    final formattedLabel = _capitalize(dayLabel).toUpperCase();
    return _GroupHeader(
      title: isToday ? "$formattedLabel · AUJOURD'HUI" : formattedLabel,
      total: total,
      count: count,
      color: isToday ? scheme.primary : scheme.onSurfaceVariant,
    );
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

class ExpenseWeekHeader extends StatelessWidget {
  final int weekNumber;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int count;
  final double total;

  const ExpenseWeekHeader({
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.count,
    required this.total,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final startLabel = DateFormat('d', 'fr_FR').format(weekStart);
    final endLabel = DateFormat('d MMM', 'fr_FR').format(weekEnd);
    final label = 'SEM. $weekNumber · $startLabel – $endLabel'.toUpperCase();
    return _GroupHeader(
      title: label,
      total: total,
      count: count,
      color: scheme.onSurfaceVariant,
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;
  final double total;
  final int count;
  final Color color;

  const _GroupHeader({
    required this.title,
    required this.total,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6, left: 2, right: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                height: 14 / 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.09 * 11,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${formatter.format(total)} · $count',
            style: TextStyle(
              fontSize: 11.5,
              height: 14 / 11.5,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
