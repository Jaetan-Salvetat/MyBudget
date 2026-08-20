import 'package:mybudget/core/services/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_settings_provider.g.dart';

@Riverpod(keepAlive: true)
class QuickAddEnabledNotifier extends _$QuickAddEnabledNotifier {
  @override
  bool build() => PreferencesService.isQuickAddEnabled();

  Future<void> setEnabled(bool enabled) async {
    await PreferencesService.setQuickAddEnabled(enabled);
    state = enabled;
  }
}
