import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
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
          return r.startDate.year * 10000 +
              r.startDate.month * 100 +
              r.startDate.day;
      }
    }

    revenues.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    return revenues;
  }

  /// Returns the id of the created row, so a caller can undo its own add.
  Future<int> addRevenue(RevenueModel revenue) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      final id = repo.add(revenue);
      ref.invalidateSelf();
      await future;
      return id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRevenue(RevenueModel updated) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      final old = repo.get(updated.id);
      if (old == null) return;

      final bool isNameOnly =
          updated.amount == old.amount &&
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

      final bool isStructural =
          updated.amount != old.amount ||
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

  /// Hard delete, whatever the recurrence : closing a row makes no sense when
  /// it was created seconds ago.
  Future<void> deletePermanently(int id) async {
    ref.read(revenueRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteRevenue(int id) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      final revenue = repo.get(id);
      if (revenue == null) return;

      if (revenue.frequencyEnum == Frequency.oneTime) {
        await deletePermanently(id);
        return;
      }

      final now = DateTime.now();
      final endDate = computeEndDate(now, revenue.startDate.day);
      repo.update(revenue.copyWith(endDate: endDate));
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

  List<RevenueModel> getRevenuesForAccount(int accountId) =>
      (state.value ?? const <RevenueModel>[])
          .where((revenue) => revenue.accountId == accountId)
          .toList();

}
