import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenues_provider.g.dart';

@Riverpod(keepAlive: true)
class RevenueNotifier extends _$RevenueNotifier {
  @override
  Future<List<RevenueModel>> build() async {
    final repo = ref.watch(revenueRepositoryProvider);
    final revenues = repo.getActive();

    int sortKey(RevenueModel r) {
      switch (r.frequencyEnum) {
        case Frequency.monthly:
          return r.startDate.day;
        case Frequency.annual:
          return r.startDate.month * 100 + r.startDate.day;
        case Frequency.oneTime:
          return r.startDate.year * 10000 + r.startDate.month * 100 + r.startDate.day;
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

  Future<void> updateRevenue(RevenueModel updated) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      final old = repo.get(updated.id);
      if (old == null) return;

      final bool isNameOnly = updated.amount == old.amount &&
          updated.frequency == old.frequency &&
          updated.accountId == old.accountId &&
          updated.beneficiaryId == old.beneficiaryId &&
          updated.name != old.name;

      if (isNameOnly) {
        final int rootId = old.parentId ?? old.id;
        final chain = repo.getChain(rootId);
        for (final entry in chain) {
          repo.update(entry.copyWith(name: updated.name));
        }
        ref.invalidateSelf();
        await future;
        return;
      }

      final bool isStructural = updated.amount != old.amount ||
          updated.frequency != old.frequency ||
          updated.accountId != old.accountId ||
          updated.beneficiaryId != old.beneficiaryId;

      if (isStructural && old.frequencyEnum != Frequency.oneTime) {
        final now = DateTime.now();
        final endDate = computeEndDate(now, old.startDate.day);
        final newStartDate = computeNewStartDate(now, old.startDate.day);
        repo.update(old.copyWith(endDate: endDate));
        final newRevenue = RevenueModel.create(
          name: updated.name,
          amount: updated.amount,
          startDate: newStartDate,
          accountId: updated.accountId,
          frequency: updated.frequency,
          beneficiaryId: updated.beneficiaryId,
          parentId: old.parentId ?? old.id,
        );
        repo.add(newRevenue);
      } else {
        repo.update(updated);
      }
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRevenue(int id) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      final revenue = repo.get(id);
      if (revenue == null) return;

      if (revenue.frequencyEnum == Frequency.oneTime) {
        repo.delete(id);
      } else {
        final now = DateTime.now();
        final endDate = computeEndDate(now, revenue.startDate.day);
        repo.update(revenue.copyWith(endDate: endDate));
      }
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  List<RevenueModel> getClosedRevenues() {
    final repo = ref.read(revenueRepositoryProvider);
    return repo.getClosed();
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
          if (revenue.startDate.month == selectedMonth.month) {
            total += revenue.amount;
          }
        case Frequency.oneTime:
          if (revenue.startDate.year == selectedMonth.year &&
              revenue.startDate.month == selectedMonth.month) {
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
