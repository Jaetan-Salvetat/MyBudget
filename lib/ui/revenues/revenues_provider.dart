import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenues_provider.g.dart';

@Riverpod(keepAlive: true)
class RevenueNotifier extends _$RevenueNotifier {
  @override
  Future<List<RevenueModel>> build() async {
    final repo = ref.watch(revenueRepositoryProvider);
    final revenues = repo.getAll();

    int sortKey(RevenueModel r) {
      switch (r.frequencyEnum) {
        case Frequency.monthly:
          return r.date.day;
        case Frequency.annual:
          return r.date.month * 100 + r.date.day;
        case Frequency.oneTime:
          return r.date.year * 10000 + r.date.month * 100 + r.date.day;
      }
    }

    revenues.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    return revenues;
  }

  Future<void> addRevenue(RevenueModel revenue) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      repo.add(revenue);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRevenue(RevenueModel revenue) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      repo.update(revenue);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRevenue(int id) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      repo.delete(id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  List<RevenueModel> _currentRevenues() => state.value ?? [];

  double getMonthlyRevenues() {
    final selectedMonth = ref.read(selectedMonthProvider);
    double total = 0.0;
    for (final revenue in _currentRevenues()) {
      switch (revenue.frequencyEnum) {
        case Frequency.monthly:
          total += revenue.amount;
        case Frequency.annual:
          if (revenue.date.month == selectedMonth.month) {
            total += revenue.amount;
          }
        case Frequency.oneTime:
          if (revenue.date.year == selectedMonth.year &&
              revenue.date.month == selectedMonth.month) {
            total += revenue.amount;
          }
      }
    }
    return total;
  }

  List<RevenueModel> getRecentRevenues(int count) =>
      _currentRevenues().take(count).toList();

  List<RevenueModel> getRevenuesForAccount(int accountId) =>
      _currentRevenues()
          .where((revenue) => revenue.accountId == accountId)
          .toList();

  double getTotalRevenuesForAccount(int accountId) =>
      getRevenuesForAccount(accountId).fold(0.0, (sum, r) => sum + r.amount);
}
