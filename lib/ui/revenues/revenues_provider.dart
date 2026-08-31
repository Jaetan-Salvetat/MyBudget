import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/entities/transaction_change_entry.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/transaction_change_service.dart';
import 'package:mybudget/models/transaction_event_model.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
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

  Future<void> updateRevenue(
    RevenueModel updated, {
    EffectiveMonth? effectiveMonth,
  }) async {
    try {
      final repo = ref.read(revenueRepositoryProvider);
      final old = repo.get(updated.id);
      if (old == null) return;

      final changesTerms = TransactionChangeService.changesTerms(old, updated);
      final forked = changesTerms && old.frequencyEnum != Frequency.oneTime;

      if (forked) {
        _fork(repo, old, updated, effectiveMonth);
      } else if (changesTerms) {
        repo.update(updated);
      }

      _recordChanges(old, updated, forked: forked);
      _recategorizeChain(repo, old, updated);

      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  void _fork(
    RevenueRepository repo,
    RevenueModel old,
    RevenueModel updated,
    EffectiveMonth? effectiveMonth,
  ) {
    final now = DateTime.now();
    final frequency = updated.frequencyEnum;
    final scope =
        effectiveMonth ??
        defaultEffectiveMonth(
          frequency: frequency,
          anchor: updated.startDate,
          asOf: now,
        );
    final startDate = startDateFor(
      frequency: frequency,
      anchor: updated.startDate,
      asOf: now,
      scope: scope,
    );
    final closing = startDate.subtract(const Duration(days: 1));

    if (hasStarted(old.startDate, closing)) {
      repo.update(old.copyWith(endDate: dayOnly(closing)));
    } else {
      repo.delete(old.id);
    }

    repo.add(
      RevenueModel.create(
        name: updated.name,
        amount: updated.amount,
        categorySlug: updated.categorySlug,
        startDate: startDate,
        accountId: updated.accountId,
        frequency: updated.frequency,
        beneficiaryId: updated.beneficiaryId,
        parentId: old.parentId ?? old.id,
      ),
    );
  }

  void _recordChanges(
    RevenueModel old,
    RevenueModel updated, {
    required bool forked,
  }) {
    final changes = TransactionChangeService.inPlaceChanges(
      old,
      updated,
      at: DateTime.now(),
      forked: forked,
    );
    if (changes.isEmpty) return;

    final events = ref.read(transactionEventRepositoryProvider);
    final rootId = old.parentId ?? old.id;
    for (final TransactionChangeEntry change in changes) {
      events.add(
        TransactionEventModel.create(
          rootId: rootId,
          type: TransactionType.income,
          entry: change,
        ),
      );
    }
  }

  void _forgetOrphanEvents(RevenueRepository repo, RevenueModel deleted) {
    final rootId = deleted.parentId ?? deleted.id;
    if (repo.getChain(rootId).isNotEmpty) return;

    ref
        .read(transactionEventRepositoryProvider)
        .deleteForRoot(rootId, TransactionType.income);
  }

  void _recategorizeChain(
    RevenueRepository repo,
    RevenueModel old,
    RevenueModel updated,
  ) {
    if (updated.categorySlug == old.categorySlug) return;

    for (final entry in repo.getChain(old.parentId ?? old.id)) {
      repo.update(entry..categorySlug = updated.categorySlug);
    }
  }

  Future<void> deletePermanently(int id) async {
    final repo = ref.read(revenueRepositoryProvider);
    final revenue = repo.get(id);
    repo.delete(id);
    if (revenue != null) _forgetOrphanEvents(repo, revenue);
    ref.invalidateSelf();
    await future;
  }

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
