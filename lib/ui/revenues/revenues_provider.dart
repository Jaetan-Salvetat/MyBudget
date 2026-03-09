import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenues_provider.g.dart';

@Riverpod(keepAlive: true)
class RevenueNotifier extends _$RevenueNotifier {
  @override
  Future<List<RevenueModel>> build() async {
    final repo = ref.watch(revenueRepositoryProvider);
    final revenues = repo.getAll();
    revenues.sort((a, b) => b.date.compareTo(a.date));
    return revenues;
  }

  Future<void> addRevenue(RevenueModel revenue) async {
    final repo = ref.read(revenueRepositoryProvider);
    repo.add(revenue);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateRevenue(RevenueModel revenue) async {
    final repo = ref.read(revenueRepositoryProvider);
    repo.update(revenue);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteRevenue(int id) async {
    final repo = ref.read(revenueRepositoryProvider);
    repo.delete(id);
    ref.invalidateSelf();
    await future;
  }

  List<RevenueModel> _currentRevenues() => state.value ?? [];

  double getMonthlyRevenues() {
    final revenues = _currentRevenues();
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

  double getMonthlyFixedRevenues() {
    final revenues = _currentRevenues();
    if (revenues.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    double total = 0.0;
    for (final revenue in revenues) {
      if (!revenue.isRegular) continue;
      final isCurrentMonth =
          (revenue.date.isAtSameMomentAs(startOfMonth) ||
              revenue.date.isAfter(startOfMonth)) &&
          revenue.date.isBefore(startOfNextMonth);
      if (isCurrentMonth) total += revenue.amount;
    }
    return total;
  }

  double getMonthlyPunctualRevenues() {
    final revenues = _currentRevenues();
    if (revenues.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    double total = 0.0;
    for (final revenue in revenues) {
      if (revenue.isRegular) continue;
      final isCurrentMonth =
          (revenue.date.isAtSameMomentAs(startOfMonth) ||
              revenue.date.isAfter(startOfMonth)) &&
          revenue.date.isBefore(startOfNextMonth);
      if (isCurrentMonth) total += revenue.amount;
    }
    return total;
  }

  List<RevenueModel> getRecentRevenues(int count) =>
      _currentRevenues().take(count).toList();

  double getTotalRevenues() =>
      _currentRevenues().fold(0.0, (sum, r) => sum + r.amount);

  List<RevenueModel> getRevenuesForAccount(int accountId) =>
      _currentRevenues()
          .where((revenue) => revenue.accountId == accountId)
          .toList();

  double getTotalRevenuesForAccount(int accountId) =>
      getRevenuesForAccount(accountId).fold(0.0, (sum, r) => sum + r.amount);
}
