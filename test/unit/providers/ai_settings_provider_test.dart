import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> initPreferences(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await PreferencesService.init();
  }

  tearDown(() => container.dispose());

  group('QuickAddEnabledNotifier', () {
    test('is enabled by default when no preference is stored', () async {
      await initPreferences({});
      container = ProviderContainer();

      expect(container.read(quickAddEnabledProvider), isTrue);
    });

    test('reads the stored preference when it is disabled', () async {
      await initPreferences({PreferencesService.keyQuickAddEnabled: false});
      container = ProviderContainer();

      expect(container.read(quickAddEnabledProvider), isFalse);
    });

    test('setEnabled(false) updates the state', () async {
      await initPreferences({});
      container = ProviderContainer();

      await container
          .read(quickAddEnabledProvider.notifier)
          .setEnabled(false);

      expect(container.read(quickAddEnabledProvider), isFalse);
    });

    test('setEnabled persists the value across containers', () async {
      await initPreferences({});
      container = ProviderContainer();

      await container
          .read(quickAddEnabledProvider.notifier)
          .setEnabled(false);
      container.dispose();
      container = ProviderContainer();

      expect(container.read(quickAddEnabledProvider), isFalse);
    });

    test('setEnabled(true) re-enables a disabled quick add', () async {
      await initPreferences({PreferencesService.keyQuickAddEnabled: false});
      container = ProviderContainer();

      await container
          .read(quickAddEnabledProvider.notifier)
          .setEnabled(true);

      expect(container.read(quickAddEnabledProvider), isTrue);
      expect(PreferencesService.isQuickAddEnabled(), isTrue);
    });
  });
}
