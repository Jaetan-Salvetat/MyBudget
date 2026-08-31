import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/transaction_event_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_queries.g.dart';

@Riverpod(keepAlive: true)
List<RevenueModel> revenueHistory(Ref ref) {
  final open = ref.watch(revenueProvider).value ?? const <RevenueModel>[];
  final closed = ref.watch(revenueRepositoryProvider).getClosed();
  return [...open, ...closed];
}

@Riverpod(keepAlive: true)
List<RevenueModel> monthRevenues(Ref ref) {
  final revenues = ref.watch(revenueHistoryProvider);
  final month = ref.watch(selectedMonthProvider);

  return [
    for (final revenue in revenues)
      if (occursInMonth(
        revenue.startDate,
        revenue.endDate,
        revenue.frequencyEnum,
        month,
      ))
        _datedOn(revenue, month),
  ];
}

RevenueModel _datedOn(RevenueModel revenue, DateTime month) {
  final landing = dayInMonthOf(revenue.startDate, revenue.frequencyEnum, month);
  if (landing == revenue.startDate) return revenue;
  return revenue.copyWith(startDate: landing);
}

@Riverpod(keepAlive: true)
List<RevenueModel> activeRevenues(Ref ref) {
  final revenues = ref.watch(revenueProvider).value ?? [];
  return revenues.where((r) => r.endDate == null).toList();
}

double _revenueAmountForMonth(RevenueModel revenue, DateTime month) {
  final falls = occursInMonth(
    revenue.startDate,
    revenue.endDate,
    revenue.frequencyEnum,
    month,
  );
  return falls ? revenue.amount : 0.0;
}

@Riverpod(keepAlive: true)
double monthlyRevenues(Ref ref) {
  final revenues = ref.watch(revenueHistoryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  double total = 0.0;
  for (final revenue in revenues) {
    total += _revenueAmountForMonth(revenue, selectedMonth);
  }
  return total;
}

@Riverpod(keepAlive: true)
double currentMonthRevenues(Ref ref) {
  final revenues = ref.watch(revenueHistoryProvider);
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

@Riverpod(keepAlive: true)
List<TransactionEventModel> revenueEvents(Ref ref, int rootId) {
  ref.watch(revenueProvider);
  return ref
      .watch(transactionEventRepositoryProvider)
      .getForRoot(rootId, TransactionType.income);
}
