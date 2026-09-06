import 'package:mybudget/core/contracts/filterable_transaction.dart';
import 'package:mybudget/core/contracts/recurring_transaction.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/rules/recurrence_rules.dart';
import 'package:mybudget/core/rules/transaction_change_rules.dart';
import 'package:mybudget/core/values/transaction_change_entry.dart';
import 'package:mybudget/data/model/transaction_event_model.dart';
import 'package:mybudget/data/repository/recurring_transaction_repository.dart';
import 'package:mybudget/data/repository/transaction_event_repository.dart';

List<T> byDueDate<T extends FilterableTransaction>(List<T> entries) {
  int dueDateKey(T entry) {
    final date = entry.startDate;
    switch (entry.frequencyEnum) {
      case Frequency.monthly:
        return date.day;
      case Frequency.annual:
        return date.month * 100 + date.day;
      case Frequency.oneTime:
        return date.year * 10000 + date.month * 100 + date.day;
    }
  }

  return entries.toList()
    ..sort((a, b) => dueDateKey(a).compareTo(dueDateKey(b)));
}

class RecurringTransactionEditor<T extends RecurringTransaction<T>> {
  const RecurringTransactionEditor({
    required this.repository,
    required this.events,
    required this.type,
    required this.now,
  });

  final RecurringTransactionRepository<T> repository;
  final TransactionEventRepository Function() events;
  final TransactionType type;
  final DateTime Function() now;

  void update(T updated, {EffectiveMonth? effectiveMonth}) {
    final old = repository.get(updated.id);
    if (old == null) return;

    final changesTerms = TransactionChangeRules.changesTerms(old, updated);
    final forked = changesTerms && old.frequencyEnum != Frequency.oneTime;

    if (forked) {
      _fork(old, updated, effectiveMonth);
    } else if (changesTerms) {
      repository.update(updated);
    }

    _recordChanges(old, updated, forked: forked);
    _recategorizeChain(old, updated);
  }

  void deletePermanently(int id) {
    final entity = repository.get(id);
    repository.delete(id);
    if (entity != null) _forgetOrphanEvents(entity);
  }

  void deleteFrom(int id, RecurringDeletion scope) {
    final entity = repository.get(id);
    if (entity == null) return;

    final closing = closingDateOf(
      scope,
      entity.startDate,
      entity.frequencyEnum,
      now(),
    );

    if (entity.frequencyEnum == Frequency.oneTime ||
        closing.isBefore(dayOnly(entity.startDate))) {
      deletePermanently(id);
      return;
    }

    repository.update(entity.closedOn(closing));
  }

  void _fork(T old, T updated, EffectiveMonth? effectiveMonth) {
    final asOf = now();
    final frequency = updated.frequencyEnum;
    final scope =
        effectiveMonth ??
        defaultEffectiveMonth(
          frequency: frequency,
          anchor: updated.startDate,
          asOf: asOf,
        );
    final startDate = startDateFor(
      frequency: frequency,
      anchor: updated.startDate,
      asOf: asOf,
      scope: scope,
    );
    final closing = startDate.subtract(const Duration(days: 1));

    if (hasStarted(old.startDate, closing)) {
      repository.update(old.closedOn(dayOnly(closing)));
    } else {
      repository.delete(old.id);
    }

    repository.add(updated.forkedAt(startDate, _rootIdOf(old)));
  }

  void _recordChanges(T old, T updated, {required bool forked}) {
    final changes = TransactionChangeRules.inPlaceChanges(
      old,
      updated,
      at: now(),
      forked: forked,
    );
    if (changes.isEmpty) return;

    final rootId = _rootIdOf(old);
    for (final TransactionChangeEntry change in changes) {
      events().add(
        TransactionEventModel.create(rootId: rootId, type: type, entry: change),
      );
    }
  }

  void _forgetOrphanEvents(T deleted) {
    final rootId = _rootIdOf(deleted);
    if (repository.getChain(rootId).isNotEmpty) return;

    events().deleteForRoot(rootId, type);
  }

  void _recategorizeChain(T old, T updated) {
    if (updated.categorySlug == old.categorySlug) return;

    for (final entry in repository.getChain(_rootIdOf(old))) {
      repository.update(entry..categorySlug = updated.categorySlug);
    }
  }

  int _rootIdOf(T entity) => entity.parentId ?? entity.id;
}
