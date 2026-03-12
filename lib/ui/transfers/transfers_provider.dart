import 'package:mybudget/core/entities/transfer.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfers_provider.g.dart';

@Riverpod(keepAlive: true)
class TransferNotifier extends _$TransferNotifier {
  @override
  Future<List<Transfer>> build() async {
    final repo = ref.watch(transferRepositoryProvider);
    final models = repo.getAll();
    return models.map(Transfer.fromModel).toList();
  }

  List<Transfer> _currentTransfers() => state.value ?? [];

  Future<void> addTransfer(TransferModel model) async {
    try {
      final repo = ref.read(transferRepositoryProvider);
      repo.add(model);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransfer(TransferModel model) async {
    try {
      final repo = ref.read(transferRepositoryProvider);
      repo.update(model);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransfer(int id) async {
    try {
      final repo = ref.read(transferRepositoryProvider);
      repo.delete(id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  List<Transfer> getTransfersForAccount(int accountId) =>
      _currentTransfers()
          .where((t) => t.fromAccountId == accountId || t.toAccountId == accountId)
          .toList();

  double getOutgoingTotalForAccount(int accountId) =>
      _currentTransfers()
          .where((t) => t.isOutgoingFrom(accountId))
          .fold(0.0, (sum, t) => sum + t.monthlyAmount);

  double getIncomingTotalForAccount(int accountId) =>
      _currentTransfers()
          .where((t) => t.isIncomingTo(accountId))
          .fold(0.0, (sum, t) => sum + t.monthlyAmount);

  double getMonthlyTransferBalance(int accountId) =>
      getIncomingTotalForAccount(accountId) - getOutgoingTotalForAccount(accountId);
}
