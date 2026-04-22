import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  group('Scan quota via PreferencesService', () {
    test('getLastScanTimestamp returns 0 when never scanned', () {
      expect(PreferencesService.getLastScanTimestamp(), 0);
    });

    test('setLastScanTimestamp persists value', () async {
      const timestamp = 1713800000;
      await PreferencesService.setLastScanTimestamp(timestamp);
      expect(PreferencesService.getLastScanTimestamp(), timestamp);
    });

    test('cooldown blocks scan within 2 minutes', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await PreferencesService.setLastScanTimestamp(now);

      final elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - PreferencesService.getLastScanTimestamp();
      final remaining = ScanException.scanCooldownSeconds - elapsed;

      expect(remaining, greaterThan(0));
    });

    test('cooldown allows scan after 2 minutes', () async {
      final twoMinutesAgo =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - ScanException.scanCooldownSeconds;
      await PreferencesService.setLastScanTimestamp(twoMinutesAgo);

      final elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - PreferencesService.getLastScanTimestamp();
      final remaining = ScanException.scanCooldownSeconds - elapsed;

      expect(remaining, lessThanOrEqualTo(0));
    });

    test('cooldown allows scan when never scanned (timestamp 0)', () {
      final elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - PreferencesService.getLastScanTimestamp();
      final remaining = ScanException.scanCooldownSeconds - elapsed;

      expect(remaining, lessThan(0));
    });

    test('remaining seconds decreases correctly', () async {
      final secondsAgo = ScanException.scanCooldownSeconds - 30;
      final timestamp =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - secondsAgo;
      await PreferencesService.setLastScanTimestamp(timestamp);

      final elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - PreferencesService.getLastScanTimestamp();
      final remaining = ScanException.scanCooldownSeconds - elapsed;

      expect(remaining, closeTo(30, 2));
    });

    test('clearAll resets scan timestamp', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await PreferencesService.setLastScanTimestamp(now);
      expect(PreferencesService.getLastScanTimestamp(), now);

      await PreferencesService.clearAll();
      expect(PreferencesService.getLastScanTimestamp(), 0);
    });
  });
}
