import 'package:mybudget/core/entities/transfer.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfers_provider.g.dart';

@Riverpod(keepAlive: true)
class TransferNotifier extends _$TransferNotifier {
  @override
  Future<List<Transfer>> build() async {
    final repo = ref.watch(transferRepositoryProvider);
    final models = repo.getActive();
    return models.map(Transfer.fromModel).toList();
  }

  List<Transfer> _currentTransfers() => state.value ?? [];

  List<Transfer> _activeTransfers() =>
      _currentTransfers().where((t) => t.endDate == null).toList();

  Future<void> addTransfer(TransferModel model) async {
    final repo = ref.read(transferRepositoryProvider);
    repo.add(model);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateTransfer(TransferModel updated) async {
    final repo = ref.read(transferRepositoryProvider);
    final old = repo.get(updated.id);
    if (old == null) return;

    final bool isNameOnly =
        updated.amount == old.amount &&
        updated.frequency == old.frequency &&
        updated.fromAccountId == old.fromAccountId &&
        updated.toAccountId == old.toAccountId &&
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
        updated.fromAccountId != old.fromAccountId ||
        updated.toAccountId != old.toAccountId;

    if (isStructural && old.frequencyEnum != Frequency.oneTime) {
      final now = ref.read(clockProvider)();
      final frequency = updated.frequencyEnum;
      final newStartDate = startDateFor(
        frequency: frequency,
        anchor: updated.startDate,
        asOf: now,
        scope: defaultEffectiveMonth(
          frequency: frequency,
          anchor: updated.startDate,
          asOf: now,
        ),
      );
      final closing = dayOnly(newStartDate).subtract(const Duration(days: 1));
      if (hasStarted(old.startDate, closing)) {
        repo.update(old.copyWith(endDate: closing));
      } else {
        repo.delete(old.id);
      }
      final newTransfer = TransferModel.create(
        name: updated.name,
        amount: updated.amount,
        fromAccountId: updated.fromAccountId,
        toAccountId: updated.toAccountId,
        startDate: newStartDate,
        frequency: updated.frequencyEnum,
        parentId: old.parentId ?? old.id,
      );
      repo.add(newTransfer);
    } else {
      repo.update(updated);
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteTransfer(int id) async {
    final repo = ref.read(transferRepositoryProvider);
    final transfer = repo.get(id);
    if (transfer == null) return;

    final now = ref.read(clockProvider)();
    if (transfer.frequencyEnum == Frequency.oneTime ||
        !hasStarted(transfer.startDate, now)) {
      repo.delete(id);
    } else {
      repo.update(transfer.copyWith(endDate: dayOnly(now)));
    }
    ref.invalidateSelf();
    await future;
  }

  List<TransferModel> getClosedTransfers() {
    final repo = ref.read(transferRepositoryProvider);
    return repo.getClosed();
  }

  List<Transfer> getTransfersForAccount(int accountId) => _currentTransfers()
      .where((t) => t.fromAccountId == accountId || t.toAccountId == accountId)
      .toList();

  List<Transfer> getActiveTransfersForAccount(int accountId) =>
      _activeTransfers()
          .where(
            (t) => t.fromAccountId == accountId || t.toAccountId == accountId,
          )
          .toList();

  double getOutgoingTotalForAccount(int accountId) => _activeTransfers()
      .where((t) => t.isOutgoingFrom(accountId))
      .fold(0.0, (sum, t) => sum + t.monthlyAmount);

  double getIncomingTotalForAccount(int accountId) => _activeTransfers()
      .where((t) => t.isIncomingTo(accountId))
      .fold(0.0, (sum, t) => sum + t.monthlyAmount);

  double getMonthlyTransferBalance(int accountId) =>
      getIncomingTotalForAccount(accountId) -
      getOutgoingTotalForAccount(accountId);
}
