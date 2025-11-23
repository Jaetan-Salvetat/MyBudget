import 'package:flutter/foundation.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/revenue_model.dart';

class RevenueViewModel extends ChangeNotifier {
  final RevenueRepository _revenueRepository;

  List<RevenueModel> _revenues = [];
  bool _isLoading = false;
  String _error = '';

  List<RevenueModel> get revenues => _revenues;
  bool get isLoading => _isLoading;
  String get error => _error;

  RevenueViewModel(this._revenueRepository) {
    loadRevenues();
  }

  Future<void> loadRevenues() async {
    try {
      _isLoading = true;
      notifyListeners();

      _revenues = _revenueRepository.getAll();

      _revenues.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRevenue(RevenueModel revenue) async {
    try {
      _isLoading = true;
      notifyListeners();

      _revenueRepository.add(revenue);
      await loadRevenues();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRevenue(RevenueModel revenue) async {
    try {
      _isLoading = true;
      notifyListeners();

      _revenueRepository.update(revenue);
      await loadRevenues();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRevenue(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      _revenueRepository.delete(id);
      await loadRevenues();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  double getMonthlyRevenues() {
    if (_revenues.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double total = 0.0;

    for (var revenue in _revenues) {
      final isCurrentMonth =
          revenue.date.isAtSameMomentAs(startOfMonth) ||
          revenue.date.isAtSameMomentAs(endOfMonth) ||
          (revenue.date.isAfter(startOfMonth) &&
              revenue.date.isBefore(endOfMonth));

      if (isCurrentMonth) {
        total += revenue.amount;
      }
    }

    return total;
  }

  double getMonthlyFixedRevenues() {
    if (_revenues.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double total = 0.0;

    for (var revenue in _revenues) {
      if (!revenue.isRegular) continue;

      final isCurrentMonth =
          revenue.date.isAtSameMomentAs(startOfMonth) ||
          revenue.date.isAtSameMomentAs(endOfMonth) ||
          (revenue.date.isAfter(startOfMonth) &&
              revenue.date.isBefore(endOfMonth));

      if (isCurrentMonth) {
        total += revenue.amount;
      }
    }

    return total;
  }

  double getMonthlyPunctualRevenues() {
    if (_revenues.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double total = 0.0;

    for (var revenue in _revenues) {
      if (revenue.isRegular) continue;

      final isCurrentMonth =
          revenue.date.isAtSameMomentAs(startOfMonth) ||
          revenue.date.isAtSameMomentAs(endOfMonth) ||
          (revenue.date.isAfter(startOfMonth) &&
              revenue.date.isBefore(endOfMonth));

      if (isCurrentMonth) {
        total += revenue.amount;
      }
    }

    return total;
  }

  List<RevenueModel> getRecentRevenues(int count) {
    return _revenues.take(count).toList();
  }

  double getTotalRevenues() {
    return _revenues.fold(0.0, (sum, revenue) => sum + revenue.amount);
  }

  List<RevenueModel> getRevenuesForAccount(int accountId) {
    return _revenues
        .where((revenue) => revenue.accountId == accountId)
        .toList();
  }

  double getTotalRevenuesForAccount(int accountId) {
    return getRevenuesForAccount(
      accountId,
    ).fold(0.0, (sum, revenue) => sum + revenue.amount);
  }
}
