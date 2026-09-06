import 'package:mybudget/core/providers/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_month_provider.g.dart';

@Riverpod(keepAlive: true)
class SelectedMonth extends _$SelectedMonth {
  @override
  DateTime build() {
    final now = ref.watch(clockProvider)();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void resetToCurrentMonth() {
    final now = ref.read(clockProvider)();
    state = DateTime(now.year, now.month);
  }
}
