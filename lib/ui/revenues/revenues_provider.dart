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

  double getMonthlyRevenues() =>
      _currentRevenues().fold(0.0, (sum, r) => sum + r.amount);

  List<RevenueModel> getRecentRevenues(int count) =>
      _currentRevenues().take(count).toList();

  List<RevenueModel> getRevenuesForAccount(int accountId) =>
      _currentRevenues()
          .where((revenue) => revenue.accountId == accountId)
          .toList();

  double getTotalRevenuesForAccount(int accountId) =>
      getRevenuesForAccount(accountId).fold(0.0, (sum, r) => sum + r.amount);
}
