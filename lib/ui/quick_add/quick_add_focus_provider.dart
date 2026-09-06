import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_focus_provider.g.dart';

@riverpod
class QuickAddFocusRequest extends _$QuickAddFocusRequest {
  @override
  int build() => 0;

  void request() => state = state + 1;
}
