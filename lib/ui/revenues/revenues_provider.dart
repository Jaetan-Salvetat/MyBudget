import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/recurring_transaction_editor.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenues_provider.g.dart';

@Riverpod(keepAlive: true)
class RevenueNotifier extends _$RevenueNotifier {
  @override
  Future<List<RevenueModel>> build() async =>
      byDueDate(ref.watch(revenueRepositoryProvider).getActive());

  RecurringTransactionEditor<RevenueModel> get _editor =>
      RecurringTransactionEditor<RevenueModel>(
        repository: ref.read(revenueRepositoryProvider),
        events: () => ref.read(transactionEventRepositoryProvider),
        type: TransactionType.income,
        now: ref.read(clockProvider),
      );

  Future<int> addRevenue(RevenueModel revenue) async {
    final id = ref.read(revenueRepositoryProvider).add(revenue);
    await _refresh();
    return id;
  }

  Future<void> updateRevenue(
    RevenueModel updated, {
    EffectiveMonth? effectiveMonth,
  }) async {
    _editor.update(updated, effectiveMonth: effectiveMonth);
    await _refresh();
  }

  Future<void> deletePermanently(int id) async {
    _editor.deletePermanently(id);
    await _refresh();
  }

  Future<void> deleteRevenue(
    int id, {
    RecurringDeletion scope = RecurringDeletion.afterThisMonth,
  }) async {
    _editor.deleteFrom(id, scope);
    await _refresh();
  }

  List<RevenueModel> getClosedRevenues() =>
      ref.read(revenueRepositoryProvider).getClosed();

  List<RevenueModel> getRevenuesForAccount(int accountId) =>
      (state.value ?? const <RevenueModel>[])
          .where((revenue) => revenue.accountId == accountId)
          .toList();

  Future<void> _refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
