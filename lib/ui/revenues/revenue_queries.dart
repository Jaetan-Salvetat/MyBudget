import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_queries.g.dart';

@Riverpod(keepAlive: true)
List<RevenueModel> activeRevenues(Ref ref) {
  final revenues = ref.watch(revenueProvider).value ?? [];
  return revenues.where((r) => r.endDate == null).toList();
}

double _revenueAmountForMonth(RevenueModel revenue, DateTime month) {
  if (!isActiveForMonth(revenue.startDate, revenue.endDate, month)) return 0.0;
  switch (revenue.frequencyEnum) {
    case Frequency.monthly:
      return revenue.amount;
    case Frequency.annual:
      return revenue.startDate.month == month.month ? revenue.amount : 0.0;
    case Frequency.oneTime:
      return revenue.startDate.year == month.year &&
              revenue.startDate.month == month.month
          ? revenue.amount
          : 0.0;
  }
}

@Riverpod(keepAlive: true)
double monthlyRevenues(Ref ref) {
  final revenues = ref.watch(revenueProvider).value ?? [];
  final selectedMonth = ref.watch(selectedMonthProvider);
  double total = 0.0;
  for (final revenue in revenues) {
    total += _revenueAmountForMonth(revenue, selectedMonth);
  }
  return total;
}

@Riverpod(keepAlive: true)
double currentMonthRevenues(Ref ref) {
  final revenues = ref.watch(revenueProvider).value ?? [];
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  double total = 0.0;
  for (final revenue in revenues) {
    total += _revenueAmountForMonth(revenue, currentMonth);
  }
  return total;
}

@Riverpod(keepAlive: true)
List<RevenueModel> upcomingRevenues(Ref ref) {
  final revenues = ref.watch(activeRevenuesProvider);
  final now = DateTime.now();
  final upcoming = revenues.where((revenue) {
    switch (revenue.frequencyEnum) {
      case Frequency.monthly:
        return revenue.startDate.day >= now.day;
      case Frequency.annual:
        return revenue.startDate.month == now.month &&
            revenue.startDate.day >= now.day;
      case Frequency.oneTime:
        final revenueDate = DateTime(
          revenue.startDate.year,
          revenue.startDate.month,
          revenue.startDate.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        return !revenueDate.isBefore(today);
    }
  }).toList();
  upcoming.sort((a, b) => a.startDate.day.compareTo(b.startDate.day));
  return upcoming;
}
