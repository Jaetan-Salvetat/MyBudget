import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_queries.g.dart';

@Riverpod(keepAlive: true)
double monthlyRevenues(Ref ref) {
  final revenues = ref.watch(revenueProvider).value ?? [];
  if (revenues.isEmpty) return 0.0;

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

  double total = 0.0;
  for (final revenue in revenues) {
    final isCurrentMonth =
        (revenue.date.isAtSameMomentAs(startOfMonth) ||
            revenue.date.isAfter(startOfMonth)) &&
        revenue.date.isBefore(startOfNextMonth);
    if (isCurrentMonth) total += revenue.amount;
  }
  return total;
}

@Riverpod(keepAlive: true)
List<RevenueModel> upcomingRevenues(Ref ref) {
  final revenues = ref.watch(revenueProvider).value ?? [];
  final now = DateTime.now();
  final upcoming = revenues.where((revenue) => revenue.date.day >= now.day).toList();
  upcoming.sort((a, b) => a.date.day.compareTo(b.date.day));
  return upcoming;
}
