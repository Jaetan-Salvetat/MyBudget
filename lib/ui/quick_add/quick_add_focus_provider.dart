import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_focus_provider.g.dart';

/// Lets a caller far from the input ask for it — the nav pill action, from
/// another tab. Only the change matters, the counter is the signal.
@riverpod
class QuickAddFocusRequest extends _$QuickAddFocusRequest {
  @override
  int build() => 0;

  void request() => state = state + 1;
}
