import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/services/preferences_service.dart';

class RevenuesGroupByNotifier extends Notifier<RevenueGroupBy> {
  @override
  RevenueGroupBy build() {
    return RevenueGroupBy.fromName(PreferencesService.getRevenuesGroupBy());
  }

  Future<void> set(RevenueGroupBy value) async {
    state = value;
    await PreferencesService.setRevenuesGroupBy(value.name);
  }
}

final revenuesGroupByProvider =
    NotifierProvider<RevenuesGroupByNotifier, RevenueGroupBy>(
      RevenuesGroupByNotifier.new,
    );
