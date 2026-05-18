import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  group('QuickAdd rate limit', () {
    test('getQuickAddCount returns 0 by default', () {
      expect(PreferencesService.getQuickAddCount(), 0);
    });

    test('incrementQuickAddCount increments counter', () async {
      await PreferencesService.incrementQuickAddCount();
      expect(PreferencesService.getQuickAddCount(), 1);

      await PreferencesService.incrementQuickAddCount();
      expect(PreferencesService.getQuickAddCount(), 2);
    });

    test('getQuickAddCount resets when month changes', () async {
      final now = DateTime.now();
      final lastMonth =
          '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        PreferencesService.keyQuickAddCount: 50,
        PreferencesService.keyQuickAddMonth: lastMonth,
      });
      await PreferencesService.init();

      expect(PreferencesService.getQuickAddCount(), 0);
    });

    test('incrementQuickAddCount resets counter on new month', () async {
      final now = DateTime.now();
      final lastMonth =
          '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        PreferencesService.keyQuickAddCount: 299,
        PreferencesService.keyQuickAddMonth: lastMonth,
      });
      await PreferencesService.init();

      await PreferencesService.incrementQuickAddCount();
      expect(PreferencesService.getQuickAddCount(), 1);
    });
  });
}
