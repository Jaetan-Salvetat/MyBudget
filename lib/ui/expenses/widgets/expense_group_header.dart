import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/text_styles.dart';

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
    final dayLabel = DateFormatter.weekdayDayMonth.format(date);
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
    final startLabel = DateFormatter.dayNumber.format(weekStart);
    final endLabel = DateFormatter.shortDayMonth.format(weekEnd);
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
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6, left: 2, right: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacingEm: 0.09,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${MoneyFormatter.formatRounded(total)} · $count',
            style: AppTextStyles.mono(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
