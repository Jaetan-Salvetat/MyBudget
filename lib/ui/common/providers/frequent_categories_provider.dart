import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'frequent_categories_provider.g.dart';

const int maxFrequentCategories = 5;

typedef _Usage = ({int count, DateTime last});

@Riverpod(keepAlive: true)
List<CategoryDisplay> frequentCategories(Ref ref, TransactionType? type) {
  final resolver = ref.watch(categoryDisplayResolverProvider).value;
  if (resolver == null) return const [];

  final usage = <String, _Usage>{};
  for (final entry in _entries(ref, type)) {
    final slug = entry.slug;
    final leaf = slug == null ? null : resolver.resolve(slug);
    if (leaf == null) continue;

    final previous = usage[leaf.slug];
    usage[leaf.slug] = (
      count: (previous?.count ?? 0) + 1,
      last: previous == null || entry.date.isAfter(previous.last)
          ? entry.date
          : previous.last,
    );
  }

  final ranked = usage.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.count.compareTo(a.value.count);
      return byCount != 0 ? byCount : b.value.last.compareTo(a.value.last);
    });

  return [
    for (final entry in ranked.take(maxFrequentCategories))
      resolver.resolve(entry.key)!,
  ];
}

Iterable<({String? slug, DateTime date})> _entries(
  Ref ref,
  TransactionType? type,
) {
  switch (type) {
    case TransactionType.expense:
      return _expenses(ref);
    case TransactionType.income:
      return _revenues(ref);
    case null:
      return _expenses(ref).followedBy(_revenues(ref));
  }
}

Iterable<({String? slug, DateTime date})> _expenses(Ref ref) =>
    (ref.watch(expenseProvider).value ?? []).map(
      (expense) => (slug: expense.categorySlug, date: expense.startDate),
    );

Iterable<({String? slug, DateTime date})> _revenues(Ref ref) =>
    (ref.watch(revenueProvider).value ?? []).map(
      (revenue) => (slug: revenue.categorySlug, date: revenue.startDate),
    );
