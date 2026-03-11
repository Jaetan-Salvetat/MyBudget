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
