import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
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

      // What the rule pays, how often, and which account it lands on : see
      // ExpenseNotifier.updateExpense for why that splits the rule and the
      // rest only corrects it.
      final bool changesTerms =
          updated.amount != old.amount ||
          updated.frequency != old.frequency ||
          updated.accountId != old.accountId;

      if (!changesTerms) {
        for (final entry in repo.getChain(old.parentId ?? old.id)) {
          repo.update(
            entry
              ..name = updated.name
              ..categorySlug = updated.categorySlug
              ..beneficiaryId = updated.beneficiaryId,
          );
        }
        ref.invalidateSelf();
        await future;
        return;
      }

      if (old.frequencyEnum != Frequency.oneTime) {
        final now = DateTime.now();
        final newStartDate = computeNewStartDate(now, old.startDate.day);
        if (hasStarted(old.startDate, now)) {
          repo.update(old.copyWith(endDate: dayOnly(now)));
        } else {
          repo.delete(old.id);
        }
        final newRevenue = RevenueModel.create(
          name: updated.name,
          amount: updated.amount,
          categorySlug: updated.categorySlug,
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

  /// A recurring rule is closed rather than erased : the months it was
  /// actually paid in are history, and history is what this app keeps. What
  /// [scope] settles is whether the month in progress is one of them.
  ///
  /// A rule left with nothing to defend — a one-off, or one closing before it
  /// ever came round — is erased instead.
  Future<void> deleteRevenue(
    int id, {
    RecurringDeletion scope = RecurringDeletion.afterThisMonth,
  }) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      final revenue = repo.get(id);
      if (revenue == null) return;

      final closing = closingDateOf(
        scope,
        revenue.startDate,
        revenue.frequencyEnum,
        DateTime.now(),
      );

      if (revenue.frequencyEnum == Frequency.oneTime ||
          closing.isBefore(dayOnly(revenue.startDate))) {
        await deletePermanently(id);
        return;
      }

      repo.update(revenue.copyWith(endDate: closing));
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
